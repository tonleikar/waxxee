class SwiperController < ApplicationController
  def index
    @vinyls = Vinyl.all.sample(20)
  end
end
