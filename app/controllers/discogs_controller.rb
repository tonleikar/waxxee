class DiscogsController < ApplicationController
  def index
    @query = params[:query].to_s.strip
    @results = []

    return if @query.blank?

    response = Discogs::Client.new.search_releases(query: @query)
    @results = response["results"] || []
  rescue Discogs::ConfigurationError, Discogs::ApiError => e
    flash.now[:alert] = e.message
  end

  def create
    vinyl = Discogs::ReleaseImporter.new.import!(
      release_id: params[:release_id],
      user: current_user
    )

    redirect_to vinyl_path(vinyl), notice: "Record imported successfully."
  rescue Discogs::ConfigurationError, Discogs::ApiError, ActiveRecord::RecordInvalid => e
    redirect_to discogs_path(query: params[:query]), alert: e.message
  end
end
