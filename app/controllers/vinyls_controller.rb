class VinylsController < ApplicationController
  def index
    @vinyls = Vinyl.all
  end

  def show
    @vinyl = Vinyl.find(params[:id])
  end

  def create
    @vinyl = Vinyl.new
    @vinyl.save
  end
end
