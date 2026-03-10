class UserVinylsController < ApplicationController
  def index
    @user_vinyls = UserVinyl.all
  end

  def create
    p params
    @user_vinyl = UserVinyl.new(vinyl_params)
    @user_vinyl.user = current_user
    @user_vinyl.save
    render json: { message: "Success!" }
  end

  def destroy
    @user_vinyl = UserVinyl.find(params[:id])
  end

  private

  def vinyl_params
    params.require(:user_vinyl).permit(:vinyl_id)
  end
end
