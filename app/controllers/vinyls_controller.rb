class VinylsController < ApplicationController
  def index
    @vinyls = Vinyl.all
    @vinyls = @vinyls.where("title ILIKE ? OR artist ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%") if params[:query].present?
  end

  def show
    @vinyl = Vinyl.find(params[:id])
  end

  def create
    @vinyl = Vinyl.new
    @vinyl.save
  end
end
