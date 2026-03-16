require "json"
require "net/http"

module Openai
  class PersonaGenerator
    DEFAULT_MODEL = ENV.fetch("OPENAI_PERSONA_MODEL", "gpt-4o-mini")
    DEFAULT_PROMPT = "Create my core Waxxee persona from my profile and saved records. Make it useful for record discovery."

    def initialize(user:, prompt: nil)
      @user = user
      @prompt = prompt.presence || DEFAULT_PROMPT
    end

    attr_reader :user, :prompt

    def model_name
      DEFAULT_MODEL
    end

    def call
      raise "OPENAI_API_KEY is missing." if ENV["OPENAI_API_KEY"].blank?

      normalize_persona(parse_persona_json(response_body))
    end

    private

    def response_body
      uri = URI("https://api.openai.com/v1/chat/completions")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{ENV.fetch('OPENAI_API_KEY')}"
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(request_payload)

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        open_timeout: 5,
        read_timeout: 40
      ) do |http|
        http.request(request)
      end

      raise "OpenAI request failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body).dig("choices", 0, "message", "content").to_s
    end

    def request_payload
      {
        model: model_name,
        temperature: 0.8,
        response_format: { type: "json_object" },
        messages: [
          {
            role: "system",
            content: <<~TEXT
              You create record-discovery catagories for Waxxee, a vinyl discovery app.
              The aim is help users find new records they'll love.
              You need to intperpret what the user inputs and return a cataogry that will return interesting results from the Discogs database. ie, if the user asks for things like led zeppelin records, dont search for led zeplin records, instead create a category that would include led zeppelin records, like "70s hard rock"
              never use the referenced artist as the main search query
              derive broader search boundaries from the reference
              prefer adjacent genre/era/style terms over exact-name matching
              only use exact artist names when the user explicitly wants that exact artist
              The API url must be a valid Discogs database search URL that would return results matching the catagory you create, and should use some mix of the genre, year, and keyword filters to hone in on the persona instead of just dumping everything into the query parameter.
              Don't duplicate parameters in the query string, use the appropriate filters instead (genre, year, style, etc). ie Dont search prog rock and then use prog rock as a genre filter, instead use the genre and style filters with valid inputs. Avoid using the search parameter as this is used for the band name or title search, and will limit results if used incorrectly. Use the genre filter for broad genres, and the style filter for more specific subgenres or descriptors.
              Return valid JSON only with these keys:
              title, summary, min_year, max_year, genres, keywords, url
              Rules:
              - title: short and specific, max 32 characters
              - summary: 1-2 sentences, no markdown
              - min_year and max_year: integers between 1900 and #{Time.current.year}
              - genres: array of 1-5 broad genres suited for filtering vinyl records
              - keywords: array of 3-8 short taste descriptors
              - url: a Discogs search URL that would return records matching this persona in this format: https://api.discogs.com/database/search?q=QUERY&genre=GENRE&year=MIN_YEAR-MAX_YEAR&type=release
            TEXT
          },
          {
            role: "user",
            content: <<~TEXT
              User request:
              #{prompt}
            TEXT
          }
        ]
      }
    end

    def parse_persona_json(content)
      JSON.parse(extract_json(content))
    rescue JSON::ParserError
      raise "OpenAI returned invalid persona JSON."
    end

    def extract_json(content)
      match = content.match(/\{.*\}/m)
      match ? match[0] : content
    end

    def normalize_persona(payload)
      current_year = Time.current.year
      genres = Array(payload["genres"]).map(&:to_s).map(&:strip).reject(&:blank?).join(" ")
      image = Unsplash::Photo.random(query: "#{genres} music")
      {
        title: payload["title"].to_s.strip.presence || "Untitled Persona",
        summary: payload["summary"].to_s.strip.presence || "A Waxxee persona based on your saved records.",
        min_year: payload["min_year"].to_i.clamp(1900, current_year),
        max_year: payload["max_year"].to_i.clamp(1900, current_year),
        genres: Array(payload["genres"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(5),
        keywords: Array(payload["keywords"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(8),
        url: payload["url"].to_s.strip.presence || "https://api.discogs.com/database/search?type=release",
        image_url: image.urls.small,
        image_credit: image.user.name
      }.then do |attributes|
        if attributes[:max_year] < attributes[:min_year]
          attributes[:min_year], attributes[:max_year] = attributes[:max_year], attributes[:min_year]
        end

        attributes
      end
    end
  end
end
