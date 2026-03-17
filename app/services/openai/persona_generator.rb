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
              ### Role
              You are the "Vinyl Visionary" for Waxxee, a record discovery app. Your job is to translate a user's specific interest into a broader, high-quality discovery category for vinyl collectors.

              ### Objective
              When a user provides an artist, album, or vibe, do NOT search for that exact item. Instead, reverse-engineer the "DNA" of that input (era, sub-genre, production style) to create a category that includes the input but focuses on discovery.

              ### Logic Rules
              1. **The "No-Mirror" Rule:** Never use the user's specific artist or album title as a search query.#{' '}
              2. **The 3-Degree Rule:** Move "three degrees" away from the input. (e.g., Input: "Daft Punk" -> Logic: French House/Filter House/90s Analog Synth -> Category: "French Touch & Retro-Future House").
              3. **Filtering Precision:** - Use `genre` for broad categories (Rock, Electronic, Jazz).
                - Use `style` for specific sub-genres (Psych Rock, Techno, Hard Bop).
                - Use `q` only for broad keywords (e.g., "lo-fi", "experimental"), never for the artist name.

              ### Technical Output Constraints
              Return ONLY a valid JSON object. Do not include prose or markdown outside the JSON.

              **JSON Schema:**
              - **title**: (string, max 32 chars) Catchy, record-store style name.
              - **summary**: (string, 1-2 sentences) Professional and inviting.
              - **min_year / max_year**: (integers) Between 1900 and 2026.
              - **genres**: (array of 1-5 strings) Valid Discogs top-level genres.
              - **keywords**: (array of 3-8 strings) Specific sonic descriptors.
              - **url**: A valid Discogs API URL following this structure, do not user spaces use %20 for spaces:
                `https://api.discogs.com/database/search?style=STYLE&genre=GENRE&year=MIN-MAX&type=release`
                (Note: Use `type=release` as we want the actual releases).
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
      image = fetch_persona_image(genres)
      {
        title: payload["title"].to_s.strip.presence || "Untitled Persona",
        summary: payload["summary"].to_s.strip.presence || "A Waxxee persona based on your saved records.",
        min_year: payload["min_year"].to_i.clamp(1900, current_year),
        max_year: payload["max_year"].to_i.clamp(1900, current_year),
        genres: Array(payload["genres"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(5),
        keywords: Array(payload["keywords"]).map(&:to_s).map(&:strip).reject(&:blank?).uniq.first(8),
        url: payload["url"].to_s.strip.presence || "https://api.discogs.com/database/search?type=release",
        image_url: image&.urls&.small,
        image_credit: image&.user&.name
      }.then do |attributes|
        if attributes[:max_year] < attributes[:min_year]
          attributes[:min_year], attributes[:max_year] = attributes[:max_year], attributes[:min_year]
        end

        attributes
      end
    end

    def fetch_persona_image(genres)
      Unsplash::Photo.random(query: "#{genres} music")
    rescue StandardError
      nil
    end
  end
end
