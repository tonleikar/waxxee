class SwiperController < ApplicationController
  def index
    @vinyls = Vinyl.all.sample(20)
    @user_vinyl = UserVinyl.new
  end
end
