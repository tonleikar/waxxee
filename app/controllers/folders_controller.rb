class FoldersController < ApplicationController
  def index
    @folders = current_user.folders.includes(:vinyls).order(name: :asc)
  end

  def show
    @folder = current_user.folders.includes(:vinyls).find(params[:id])
  end

  def new
    @folder = Folder.new
  end

  def create
    @folder = current_user.folders.new(folder_params)
    if @folder.save
      redirect_back fallback_location: vinyls_path, notice: "Folder created."
    else
      redirect_back fallback_location: vinyls_path, alert: "Could not create folder."
    end
  end

  def destroy
    @folder = current_user.folders.find(params[:id])
    @folder.destroy
    redirect_back fallback_location: vinyls_path, notice: "Folder deleted."
  end

  private

  def folder_params
    params.require(:folder).permit(:name)
  end
end
