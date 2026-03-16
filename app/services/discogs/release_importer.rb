module Discogs
  class ReleaseImporter
    def initialize(client: Discogs::Client.new)
      @client = client
    end

    def import!(release_id:, user: nil, cover_image: nil)
      payload = client.find_release(release_id)
      vinyl = find_or_initialize_vinyl(payload)

      vinyl.assign_attributes(vinyl_attributes(payload, cover_image: cover_image))
      vinyl.save!

      return vinyl unless user

      UserVinyl.find_or_create_by!(user: user, vinyl: vinyl)
    end

    private

    attr_reader :client

    def find_or_initialize_vinyl(payload)
      Vinyl.find_or_initialize_by(
        title: payload["title"],
        artist: artist_name(payload),
        year: release_year(payload)
      )
    end

    def vinyl_attributes(payload, cover_image:)
      {
        title: payload["title"],
        artist: artist_name(payload),
        year: release_year(payload),
        format: format_name(payload),
        genre: Array(payload["genres"]).join(", "),
        tracks: track_titles(payload),
        artwork_url: artwork_url(payload, cover_image: cover_image),
        discogs_url: discogs_url(payload)
      }
    end

    def artist_name(payload)
      Array(payload["artists"]).filter_map { |artist| artist["name"] }.join(", ")
    end

    def release_year(payload)
      payload["year"].presence || payload["released"]&.to_s&.slice(0, 4)&.to_i
    end

    def format_name(payload)
      Array(payload["formats"]).filter_map { |format| format["name"] }.join(", ")
    end

    def track_titles(payload)
      Array(payload["tracklist"]).filter_map { |track| track["title"].presence }
    end

    def artwork_url(payload, cover_image:)
      primary_image = Array(payload["images"]).find { |image| image["type"] == "primary" }
      primary_image&.fetch("uri", nil) || cover_image.presence || payload["thumb"]
    end

    def discogs_url(payload)
      payload["uri"].presence || payload["resource_url"].presence || release_fallback_url(payload)
    end

    def release_fallback_url(payload)
      release_id = payload["id"].presence
      "https://www.discogs.com/release/#{release_id}" if release_id
    end
  end
end
