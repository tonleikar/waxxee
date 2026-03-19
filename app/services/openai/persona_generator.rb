require "json"
require "net/http"

module Openai
  class PersonaGenerator
    DEFAULT_MODEL = ENV.fetch("OPENAI_PERSONA_MODEL", "gpt-5.4-mini")
    DEFAULT_PROMPT = "Create my core Waxxee persona from my profile and saved records. Make it useful for record discovery."

    def initialize(user:, prompt: nil)
      @user = user
      @prompt = prompt.presence || DEFAULT_PROMPTs
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
              You create record-discovery personas for Waxxee, a vinyl collection app.
              Return valid JSON only with these keys:
              title, summary, min_year, max_year, genres, keywords, url.
              Rules:
              - title: short and specific, max 32 characters
              - summary: 1-2 sentences, no markdown
              - min_year and max_year: integers between 1900 and #{Time.current.year}
              - genres: array of 1-5 broad genres suited for filtering vinyl records
              - keywords: array of 3-8 short taste descriptors
              - url: a Discogs search URL that would return records matching this persona in this format: https://api.discogs.com/database/search?&style=GENRES&year=MIN_YEAR-MAX_YEAR&type=release

              These are the categories to build the query string for the api URL:

                genre
                - use genre to build the following part of query string:
                genre=[jazz]
                replace [jazz] with one of the following based off the user input: ["Rock", "Electronic", "Pop", "Folk, World, & Country", "Jazz", "Funk / Soul", "Classical", "Hip Hop", "Latin", "Stage & Screen", "Reggae", "Blues"]

                style
                - use style to build the following part of query string:
                style=[style]
                replace [style] with one of the following based off the user input:
                [
                  "Pop Rock", "House", "Vocal", "Experimental", "Punk", "Alternative Rock",
                  "Synth-pop", "Techno", "Indie Rock", "Ambient", "Soul", "Hardcore", "Disco",
                  "Folk", "Ballad", "Country", "Hard Rock", "Electro", "Rock & Roll", "Chanson",
                  "Romantic", "Trance", "Heavy Metal", "Psychedelic Rock", "Soundtrack",
                  "Folk Rock", "Downtempo", "Noise", "Schlager", "Prog Rock", "Funk",
                  "Classic Rock", "Black Metal", "Easy Listening", "Tech House", "Blues Rock",
                  "Deep House", "Rhythm & Blues", "New Wave", "Industrial", "Classical",
                  "Death Metal", "Progressive House", "Drum n Bass", "Euro House", "Soft Rock",
                  "Garage Rock", "Abstract", "Gospel", "Europop", "Minimal", "Baroque",
                  "Acoustic", "Thrash", "Modern", "Swing", "Big Band", "Indie Pop", "Drone",
                  "Dub", "Country Rock", "Contemporary Jazz", "Breakbeat", "Opera", "Holiday",
                  "Progressive Trance", "Contemporary R&B", "Contemporary", "IDM", "African",
                  "Dancehall", "Breaks", "Post-Punk", "Dark Ambient", "Art Rock", "Dance-pop",
                  "Fusion", "Reggae", "Gangsta", "Doom Metal", "Religious", "Pop Rap",
                  "Avantgarde", "Beat", "Instrumental", "Electro House", "Acid", "Hard Trance",
                  "Score", "Rockabilly", "Comedy", "Jazz-Funk", "Theme", "Lo-Fi", "Roots Reggae",
                  "RnB/Swing", "Grindcore", "Leftfield", "Ska", "Post Rock", "Bolero",
                  "Spoken Word", "Psy-Trance", "Soul-Jazz", "Power Pop", "Dubstep", "Glam",
                  "Salsa", "New Age", "Conscious", "Bop", "Hip Hop", "Goth Rock", "Modern Classical",
                  "Cumbia", "Jazz-Rock", "J-pop", "Emo", "Choral", "Hard House", "Free Improvisation",
                  "Musical", "Trip Hop", "Latin Jazz", "Stoner Rock", "Volksmusik", "EBM",
                  "Shoegaze", "Italo-Disco", "MPB", "Doo Wop", "Jungle", "Surf", "Story",
                  "Field Recording", "Hardstyle", "Pop Punk", "Synthwave", "Hard Bop", "Tango",
                  "Free Jazz", "Trap", "Samba", "Oi", "Darkwave", "Radioplay", "Garage House",
                  "Celtic", "Cool Jazz", "Post Bop", "Vaporwave", "Bluegrass", "Metalcore",
                  "Eurodance", "Laïkó", "Happy Hardcore", "Polka", "UK Garage", "Kayōkyoku",
                  "Tribal", "Hardcore Hip-Hop", "Novelty", "Smooth Jazz", "Grunge",
                  "Progressive Metal", "Flamenco", "Orchestra", "AOR", "Italodance", "Nu Metal",
                  "Dixieland", "Boom Bap", "Arena Rock", "Symphonic Rock", "Southern Rock",
                  "Hindustani", "Rumba", "Parody", "Latin", "Future Jazz", "Glitch",
                  "Harsh Noise Wall", "Power Metal", "Cha-Cha", "Merengue", "Audiobook",
                  "Dub Techno", "Space Rock", "Bossa Nova", "Krautrock", "Post-Hardcore",
                  "Gabber", "Ranchera", "Speed Metal", "Neo-Classical", "Breakcore",
                  "Jazzy Hip-Hop", "Avant-garde Jazz", "Hi NRG", "Poetry", "Power Electronics",
                  "Reggae-Pop", "Bollywood", "Acid House", "Boogie", "Dungeon Synth", "Marches",
                  "Minimal Techno", "Renaissance", "Sludge Metal", "Musique Concrète", "Nu-Disco",
                  "Electric Blues", "Concerto", "Mambo", "Mod", "Bass Music", "Chiptune",
                  "Bossanova", "Country Blues", "Acid Jazz", "Freestyle", "Interview",
                  "Berlin-School", "Tribal House", "Light Music", "Indian Classical", "Math Rock",
                  "Big Beat", "Thug Rap", "Modal", "Mandopop", "Calypso", "Psychedelic", "Piano",
                  "Impressionist", "Education", "Chicago Blues", "Broken Beat", "Neofolk",
                  "Ethereal", "Neo Soul", "Rocksteady", "Crust", "Operetta", "Afrobeat",
                  "Video Game Music", "Guaracha", "Afro-Cuban", "Goregrind", "Chillwave",
                  "Britpop", "Lounge", "G-Funk", "Symphony", "Melodic Death Metal", "Grime",
                  "Euro-Disco", "Ragtime", "Éntekhno", "Hip-House", "Gothic Metal", "Deep Techno",
                  "Canzone Napoletana", "Goa Trance", "Dream Pop", "Brass Band", "Nursery Rhymes",
                  "Lovers Rock", "Organ", "Symphonic Metal", "K-pop", "Psychobilly", "Tech Trance",
                  "Hard Techno", "Dialogue", "Rhythmic Noise", "Atmospheric Black Metal",
                  "Medieval", "Son", "Neo-Romantic", "Cut-up/DJ", "City Pop", "Pacific",
                  "Speedcore", "Twist", "Nordic", "New Jack Swing", "Guaguancó", "Military",
                  "Eurobeat", "Promotional", "Educational", "Ragga", "Honky Tonk", "Hands Up",
                  "String Instrument", "Deathcore", "Mariachi", "Space-Age", "Ragga HipHop",
                  "Melodic Hardcore", "Political", "Funk Metal", "Fado", "Sound Collage",
                  "J-Rock", "Romani", "Hawaiian", "Acid Rock", "Music Hall", "Chamber Music",
                  "Reggaeton", "Anison", "Folk Metal", "Soukous", "Highlife", "Soca", "Noisecore",
                  "Sonata", "Witch House", "Freetekno", "Post-Metal", "Horrorcore", "Zouk",
                  "Afro-Cuban Jazz", "Makina", "Speech", "Monolog", "Alt-Pop", "Piano Blues",
                  "Jazzdance", "Delta Blues", "Electroacoustic", "Vallenato", "Coldwave",
                  "Modern Electric Blues", "Alternative Metal", "Norteño", "Luk Thung",
                  "Bubblegum", "Public Broadcast", "Cubano", "New Beat", "Noise Rock", "Forró",
                  "Oratorio", "Corrido", "Enka", "Italo House", "Gypsy Jazz"
                  ];

                country
                - use country to build the following part of query string:
                country=[country]
                replace [country] with the appropriate country from this list:
                [
                  "US", "UK", "Germany", "France", "Japan", "Italy", "Europe", "Canada",
                  "Unknown", "Netherlands", "Spain", "Australia", "Russia", "Brazil",
                  "Sweden", "Belgium", "Worldwide", "Greece", "Poland", "Mexico",
                  "Finland", "Jamaica", "Switzerland", "Argentina", "USSR", "Denmark",
                  "Portugal", "Norway", "Austria", "New Zealand", "South Africa",
                  "UK & Europe", "Colombia", "Yugoslavia", "USA & Canada", "Hungary",
                  "India", "Ukraine", "Turkey", "Czech Republic", "Romania", "Taiwan",
                  "Czechoslovakia", "Indonesia", "South Korea", "Ireland", "Venezuela",
                  "Chile", "Peru", "Israel", "Thailand", "Bulgaria", "Malaysia",
                  "Philippines", "China", "Scandinavia", "German Democratic Republic (GDR)",
                  "Hong Kong", "Ecuador", "Croatia", "USA & Europe", "Serbia", "Lithuania",
                  "Singapore", "Germany, Austria, & Switzerland", "UK, Europe & US", "Bolivia",
                  "Slovenia", "Slovakia", "Iceland", "Uruguay", "UK & Ireland", "Australasia",
                  "Australia & New Zealand", "Nigeria", "Estonia", "Lebanon",
                  "USA, Canada & Europe", "Panama", "Benelux", "UK & US", "Costa Rica",
                  "Pakistan", "Egypt", "Cuba", "Latvia", "Puerto Rico", "Middle East",
                  "Kenya", "Iran", "Guatemala", "Morocco", "Belarus", "Saudi Arabia",
                  "Barbados", "Macedonia", "Trinidad & Tobago", "Algeria",
                  "Bosnia & Herzegovina", "Luxembourg", "Czech Republic & Slovakia",
                  "USA, Canada & UK", "Zimbabwe", "Singapore, Malaysia & Hong Kong", "Ghana",
                  "Madagascar", "El Salvador", "North America (inc Mexico)",
                  "Dominican Republic", "Congo, Democratic Republic of the", "Reunion",
                  "France & Benelux", "Ivory Coast", "Tunisia", "United Arab Emirates",
                  "Zaire", "Angola", "Serbia and Montenegro", "Georgia", "Zambia", "Malta",
                  "Asia", "Germany & Switzerland", "Singapore & Malaysia", "Rhodesia",
                  "Mauritius", "Cyprus", "Mozambique", "Russia & CIS", "Syria", "Kazakhstan",
                  "Nicaragua", "Azerbaijan", "Ethiopia", "Vietnam", "South Vietnam",
                  "Paraguay", "Senegal", "Moldova, Republic of", "Guadeloupe", "Haiti",
                  "UK & France", "Bahamas, The", "Suriname", "Sri Lanka", "Faroe Islands",
                  "Gulf Cooperation Council", "South America"
                ]

                release year
                - use year to build the following part of the query string, format should be in a range of years.
                releaseyear=[1996-2026]

                Example 1:
                Input: "I love 70s afrobeat show me some cool songs"
                Output {
                  url: "https://api.discogs.com/database/search?style=Afrobeat&genre=Funk+/+Soul&type=releaseyear=1970-1989"
                  genres: ["Funk", "Soul", "Afrobeat"],
                  keywords: ["Funk", "Soul", "Afrobeat"],
                  summary: "Rhythmic grooves, vibrant percussion, and infectio...",
                  title: "afrobeat",
                  max_year: 1989,
                  min_year: 1970
                }
                Example 2:
                Input: "90s uk garage"
                Output {
                  url: "https://api.discogs.com/database/search?style=UK+Garage&type=releaseyear=1996-2022&country=uk"
                  genres: ["Electronic", "Dance", "UK Garage"],
                  keywords: ["Electronic", "Dance", "UK Garage"],
                  summary: "ukg's signature blend of shuffling beats, soulful ...",
                  title: "uk garage",
                  max_year: 1999,
                  min_year: 1988,
                }
            TEXT
          },
          {
            role: "user",
            content: <<~TEXT
              User input:
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
