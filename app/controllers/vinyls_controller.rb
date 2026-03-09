class VinylsController < ApplicationController
  def show
    @vinyl = Vinyl.find(params[:id])
  end

  def create
    @vinyl = Vinyl.new
    @vinyl.save
  end
end
