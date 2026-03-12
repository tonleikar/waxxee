class FolderVinylsController < ApplicationController
  def create
    folder = current_user.folders.find(folder_vinyl_params[:folder_id])
    user_vinyl = current_user.user_vinyls.includes(:folders, :folder_vinyls).find_or_create_by!(vinyl_id: folder_vinyl_params[:vinyl_id])

    FolderVinyl.find_or_create_by!(folder: folder, user_vinyl: user_vinyl)

    if turbo_frame_request?
      render_crate_controls(user_vinyl.vinyl, user_vinyl)
    else
      redirect_back fallback_location: vinyls_path, notice: "Vinyl added to folder."
    end
  end

  def destroy
    folder_vinyl = FolderVinyl.joins(:folder, :user_vinyl)
                             .where(folders: { user_id: current_user.id }, user_vinyls: { user_id: current_user.id })
                             .find(params[:id])
    vinyl = folder_vinyl.user_vinyl.vinyl
    folder_vinyl.destroy!

    user_vinyl = current_user.user_vinyls.includes(:folders, :folder_vinyls).find_by(vinyl_id: vinyl.id)

    if turbo_frame_request?
      render_crate_controls(vinyl, user_vinyl)
    else
      redirect_back fallback_location: vinyls_path, notice: "Vinyl removed from folder."
    end
  end

  private

  def folder_vinyl_params
    params.require(:folder_vinyl).permit(:folder_id, :vinyl_id)
  end

  def render_crate_controls(vinyl, user_vinyl)
    render partial: "vinyls/crate_controls",
           locals: {
             vinyl: vinyl,
             user_vinyl: user_vinyl,
             vinyl_folder_ids: user_vinyl ? user_vinyl.folders.map(&:id) : [],
             folders: current_user.folders.order(name: :asc),
             expanded: true
           }
  end
end
