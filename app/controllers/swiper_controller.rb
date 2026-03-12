class SwiperController < ApplicationController
  def index
    @vinyls = Vinyl.all.sample(20)
    @user_vinyl = UserVinyl.new
    @key = ENV["DISCOGS_CONSUMER_KEY"]
    @secret = ENV["DISCOGS_CONSUMER_SECRET"]
  end

  def card
    @vinyl = Vinyl.find(params[:id])
    render partial: "swiper/vinyl_card", locals: { vinyl: @vinyl }
  end
end
