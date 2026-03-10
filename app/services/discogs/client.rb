require "json"
require "net/http"

module Discogs
  class Error < StandardError; end
  class ConfigurationError < Error; end

  class ApiError < Error
    attr_reader :status, :body

    def initialize(message, status:, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  class Client
    def initialize(
      base_url: Rails.configuration.x.discogs.base_url,
      token: Rails.configuration.x.discogs.token,
      user_agent: Rails.configuration.x.discogs.user_agent
    )
      @base_url = base_url
      @token = token
      @user_agent = user_agent
      validate_configuration!
    end

    def search_releases(query:, page: 1, per_page: 12)
      get("/database/search", q: query, type: "release", page: page, per_page: per_page)
    end

    def find_release(release_id)
      get("/releases/#{release_id}")
    end

    private

    attr_reader :base_url, :token, :user_agent

    def validate_configuration!
      raise ConfigurationError, "Discogs token is missing" if token.blank?
      raise ConfigurationError, "Discogs user agent is missing" if user_agent.blank?
    end

    def get(path, params = {})
      uri = URI.join(base_url, path)
      uri.query = URI.encode_www_form(params) if params.any?

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 10
      ) do |http|
        http.request(build_request(uri))
      end

      parse_response(response)
    rescue JSON::ParserError => e
      raise ApiError.new("Discogs returned invalid JSON", status: 502, body: e.message)
    rescue Timeout::Error, Errno::ECONNREFUSED, SocketError => e
      raise ApiError.new("Discogs request failed: #{e.message}", status: 502)
    end

    def build_request(uri)
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = user_agent
      request["Authorization"] = "Discogs token=#{token}"
      request
    end

    def parse_response(response)
      body = response.body.present? ? JSON.parse(response.body) : {}
      return body if response.is_a?(Net::HTTPSuccess)

      message = body.is_a?(Hash) ? body["message"] : response.body
      raise ApiError.new(
        "Discogs API error: #{message || response.code}",
        status: response.code.to_i,
        body: body
      )
    end
  end
end
