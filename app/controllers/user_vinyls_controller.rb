class UserVinylsController < ApplicationController
  def index
    @user_vinyls = UserVinyl.all
  end

  def create
    vinyl = if vinyl_params[:vinyl_id].present?
      Vinyl.find(vinyl_params[:vinyl_id])
    else
      find_or_create_vinyl_from_payload
    end

    @user_vinyl = UserVinyl.find_or_create_by!(user: current_user, vinyl: vinyl)
    render json: { message: "#{@user_vinyl.vinyl.title.truncate(25, omission: '...')} added to collection." }
  end

  def destroy
    @user_vinyl = current_user.user_vinyls.find(params[:id])
    @user_vinyl.destroy!
    redirect_back fallback_location: vinyls_path, notice: "Vinyl removed from collection."
  end

  private

  def vinyl_params
    params.fetch(:user_vinyl, {}).permit(:vinyl_id)
  end

  def vinyl_payload
    params.require(:vinyl).permit!.to_h
  end

  def find_or_create_vinyl_from_payload
    attributes = Discogs::SearchResult.new(vinyl_payload).vinyl_attributes
    vinyl = Vinyl.find_or_initialize_by(
      title: attributes[:title],
      artist: attributes[:artist],
      year: attributes[:year]
    )

    vinyl.assign_attributes(attributes)
    vinyl.save!
    vinyl
  end
end
