class FolderVinylsController < ApplicationController
  def create
    folder = current_user.folders.find(folder_vinyl_params[:folder_id])
    user_vinyl = current_user.user_vinyls.includes(:folders, :folder_vinyls).find_or_create_by!(vinyl_id: folder_vinyl_params[:vinyl_id])

    FolderVinyl.find_or_create_by!(folder: folder, user_vinyl: user_vinyl)
    user_vinyl = current_user.user_vinyls.includes(:folders, :folder_vinyls).find_by!(vinyl_id: folder_vinyl_params[:vinyl_id])

    if turbo_frame_request?
      render_crate_updates(user_vinyl.vinyl, user_vinyl)
    else
      redirect_back fallback_location: vinyls_path, notice: "Vinyl added to folder."
    end
  end

  def destroy
    folder_vinyl = FolderVinyl.joins(:folder, :user_vinyl)
                             .where(folders: { user_id: current_user.id }, user_vinyls: { user_id: current_user.id })
                             .find(params[:id])
    compact = ActiveModel::Type::Boolean.new.cast(params[:compact])
    vinyl = folder_vinyl.user_vinyl.vinyl
    folder_vinyl.destroy!

    user_vinyl = current_user.user_vinyls.includes(:folders, :folder_vinyls).find_by(vinyl_id: vinyl.id)

    if compact && request.xhr?
      render_crates_list_update
    elsif turbo_frame_request? || request.xhr?
      render_crate_updates(vinyl, user_vinyl)
    else
      redirect_back fallback_location: vinyls_path, notice: "Vinyl removed from folder."
    end
  end

  private

  def folder_vinyl_params
    params.require(:folder_vinyl).permit(:folder_id, :vinyl_id)
  end

  def render_crate_updates(vinyl, user_vinyl)
    render turbo_stream: [
      turbo_stream.replace(
        crate_frame_id(vinyl),
        partial: "vinyls/crate_controls",
        locals: crate_control_locals(vinyl, user_vinyl)
      ),
      turbo_stream.replace(
        "vinyl_crates_list_panel",
        partial: "vinyls/crates_list",
        locals: { folders: current_user.folders.order(name: :asc) }
      )
    ]
  end

  def render_crates_list_update
    render turbo_stream: turbo_stream.replace(
      "vinyl_crates_list_panel",
      partial: "vinyls/crates_list",
      locals: { folders: current_user.folders.order(name: :asc) }
    )
  end

  def crate_control_locals(vinyl, user_vinyl)
    compact = ActiveModel::Type::Boolean.new.cast(params[:compact])
    current_folder = compact && params[:current_folder_id].present? ? current_user.folders.find_by(id: params[:current_folder_id]) : nil

    {
      vinyl: vinyl,
      user_vinyl: user_vinyl,
      vinyl_folder_ids: user_vinyl ? user_vinyl.folders.map(&:id) : [],
      folders: current_user.folders.order(name: :asc),
      compact: compact,
      current_folder: current_folder,
      expanded: true
    }
  end

  def crate_frame_id(vinyl)
    compact = ActiveModel::Type::Boolean.new.cast(params[:compact])
    current_folder_id = params[:current_folder_id]

    if compact && current_folder_id.present?
      "vinyl_crate_controls_#{vinyl.id}_folder_#{current_folder_id}"
    else
      "vinyl_crate_controls_#{vinyl.id}"
    end
  end
end
