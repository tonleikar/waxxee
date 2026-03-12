class UserVinylsController < ApplicationController
  def index
    @user_vinyls = UserVinyl.all
  end

  def create
    return render json: { error: "Missing vinyl_id." }, status: :unprocessable_entity if vinyl_params[:vinyl_id].blank?

    vinyl = Vinyl.find(vinyl_params[:vinyl_id])

    @user_vinyl = UserVinyl.find_or_create_by!(user: current_user, vinyl: vinyl)
    render json: {
      id: @user_vinyl.id,
      vinyl_id: vinyl.id,
      saved: true,
      message: "#{@user_vinyl.vinyl.title.truncate(25, omission: '...')} added to collection."
    }, status: :created
  end

  def destroy
    @user_vinyl = current_user.user_vinyls.find(params[:id])
    current_user.update!(favorite_vinyl_id: nil) if current_user.favorite_vinyl_id == @user_vinyl.vinyl_id
    @user_vinyl.destroy!
    redirect_back fallback_location: vinyls_path, notice: "Vinyl removed from collection."
  end

  private

  def vinyl_params
    params.fetch(:user_vinyl, {}).permit(:vinyl_id)
  end

end
