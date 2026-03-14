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
              You create record-discovery personas for Waxxee, a vinyl discovery app.
              The aim is help users find new records they'll love based on their profile and saved records.
              Obscure and niche personas are encouraged, but not required.
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
              User profile:
              #{JSON.pretty_generate(profile_context)}

              User request:
              #{prompt}
            TEXT
          }
        ]
      }
    end

    def profile_context
      recent_records = user.user_vinyls.includes(:vinyl).order(created_at: :desc).limit(18).map do |user_vinyl|
        vinyl = user_vinyl.vinyl
        {
          title: vinyl.title,
          artist: vinyl.artist,
          year: vinyl.year,
          genre: vinyl.genre
        }
      end

      genres = recent_records.filter_map { |record| record[:genre].presence }
      years = recent_records.filter_map { |record| record[:year].presence }

      {
        name: user.name,
        username: user.username,
        favorite_genre: user.favorite_genre,
        favorite_vinyl: favorite_vinyl_context,
        saved_record_count: user.vinyls.count,
        top_genres: genres.tally.sort_by { |_genre, count| -count }.first(5).to_h,
        year_span: years.min && years.max ? { min: years.min, max: years.max } : nil,
        recent_records: recent_records
      }
    end

    def favorite_vinyl_context
      return unless user.favorite_vinyl

      {
        title: user.favorite_vinyl.title,
        artist: user.favorite_vinyl.artist,
        year: user.favorite_vinyl.year,
        genre: user.favorite_vinyl.genre
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

      {
        title: payload["title"].to_s.strip.presence || "Untitled Persona",
        summary: payload["summary"].to_s.strip.presence || "A Waxxee persona based on your saved records.",
        min_year: payload["min_year"].to_i.clamp(1900, current_year),
        max_year: payload["max_year"].to_i.clamp(1900, current_year),
        genres: Array(payload["genres"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(5),
        keywords: Array(payload["keywords"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(8),
        url: payload["url"].to_s.strip.presence || "https://api.discogs.com/database/search?type=release",
        image_url: Unsplash::Photo.random(query: payload["title"] + "music")&.id || "1667936505833-d1aa8466f84b"

      }.then do |attributes|
        if attributes[:max_year] < attributes[:min_year]
          attributes[:min_year], attributes[:max_year] = attributes[:max_year], attributes[:min_year]
        end

        attributes
      end
    end
  end
end
