module Discogs
  class SearchResult
    def initialize(payload)
      @payload = payload.deep_stringify_keys
    end

    def preview_attributes
      {
        discogs_id: payload["id"],
        title: title,
        artist: artist,
        artwork_url: artwork_url,
        year: year,
        genre: genre,
        format: format
      }
    end

    def vinyl_attributes
      preview_attributes.except(:discogs_id)
    end

    private

    attr_reader :payload

    def title
      split_title.last.presence || payload["title"].to_s
    end

    def artist
      payload["artist"].presence || split_title.first.presence || Array(payload["artists"]).filter_map { |item| item["name"].presence }.join(", ")
    end

    def year
      payload["year"].presence || payload["released"]&.to_s&.slice(0, 4)&.to_i
    end

    def genre
      Array(payload["genre"] || payload["genres"] || payload["style"] || payload["styles"]).reject(&:blank?).join(", ")
    end

    def format
      Array(payload["format"] || payload["formats"]).filter_map do |item|
        item.is_a?(Hash) ? item["name"].presence : item.presence
      end.join(", ")
    end

    def artwork_url
      payload["cover_image"].presence || payload["thumb"].presence
    end

    def split_title
      raw_title = payload["title"].to_s
      return @split_title if defined?(@split_title)

      @split_title = raw_title.include?(" - ") ? raw_title.split(" - ", 2) : [nil, raw_title]
    end
  end
end