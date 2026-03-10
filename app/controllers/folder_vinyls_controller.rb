class FolderVinylsController < ApplicationController
  def create
    folder = current_user.folders.find(folder_vinyl_params[:folder_id])
    user_vinyl = current_user.user_vinyls.find_or_create_by!(vinyl_id: folder_vinyl_params[:vinyl_id])

    FolderVinyl.find_or_create_by!(folder: folder, user_vinyl: user_vinyl)

    redirect_back fallback_location: vinyls_path, notice: "Vinyl added to folder."
  end

  def destroy
    folder_vinyl = FolderVinyl.joins(:folder, :user_vinyl)
                             .where(folders: { user_id: current_user.id }, user_vinyls: { user_id: current_user.id })
                             .find(params[:id])
    folder_vinyl.destroy!

    redirect_back fallback_location: vinyls_path, notice: "Vinyl removed from folder."
  end

  private

  def folder_vinyl_params
    params.require(:folder_vinyl).permit(:folder_id, :vinyl_id)
  end
end
