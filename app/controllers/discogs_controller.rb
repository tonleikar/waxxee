class DiscogsController < ApplicationController
  def index # rubocop:disable Metrics/MethodLength
    @query = params[:query].to_s.strip
    @results = []
    @saved_vinyl_keys = current_user.user_vinyls.includes(:vinyl).to_set do |user_vinyl|
      vinyl = user_vinyl.vinyl
      [vinyl.title, vinyl.artist, vinyl.year]
    end

    return if @query.blank?

    response = Discogs::Client.new.search_releases(query: @query)
    normalized_results = (response["results"] || []).map do |result|
      artist_name, release_title = result["title"].to_s.split(" - ", 2)
      normalized_title = release_title || result["title"]
      normalized_year = result["year"].to_i

      {
        id: result["id"],
        title: normalized_title,
        artist: artist_name,
        year: normalized_year,
        country: result["country"],
        thumb: result["thumb"],
        saved: @saved_vinyl_keys.include?([normalized_title, artist_name, normalized_year])
      }
    end

    @results = normalized_results.uniq { |result| [result[:title], result[:artist]] }
  rescue Discogs::ConfigurationError, Discogs::ApiError => e
    flash.now[:alert] = e.message
  end

  def create
    Discogs::ReleaseImporter.new.import!(
      release_id: params[:release_id],
      user: current_user
    )

    redirect_to discogs_path(query: params[:query]), notice: "Saved to my collection."
  rescue Discogs::ConfigurationError, Discogs::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to discogs_path(query: params[:query]), alert: e.message
  end
end
