class SwiperController < ApplicationController
  def index
    @key = ENV["DISCOGS_CONSUMER_KEY"]
    @secret = ENV["DISCOGS_CONSUMER_SECRET"]
  end

  def card_preview
    vinyl = Discogs::SearchResult.new(vinyl_payload).preview_attributes
    render partial: "swiper/vinyl_card", locals: { vinyl: vinyl }
  end

  private

  def vinyl_payload
    params.require(:vinyl).permit!.to_h
  end
end
