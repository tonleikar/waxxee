class UserVinylsController < ApplicationController
  def index
    @user_vinyls = UserVinyl.all
  end

  def create
    @user_vinyl = UserVinyl.find_or_create_by!(user: current_user, vinyl_id: vinyl_params[:vinyl_id])
    render json: { message: "#{@user_vinyl.vinyl.title.truncate(25, omission: '...')} added to collection." }
  end

  def destroy
    @user_vinyl = current_user.user_vinyls.find(params[:id])
    @user_vinyl.destroy!
    redirect_back fallback_location: vinyls_path, notice: "Vinyl removed from collection."
  end

  private

  def vinyl_params
    params.require(:user_vinyl).permit(:vinyl_id)
  end
end
