class DiscogsController < ApplicationController
  def index
    @query = params[:query].to_s.strip
    @results = []

    return if @query.blank?

    response = Discogs::Client.new.search_releases(query: @query)
    @results = response["results"] || []
  end
end
