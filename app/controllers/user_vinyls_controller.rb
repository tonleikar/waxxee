class UserVinylsController < ApplicationController
  def index
    @user_vinyls = UserVinyl.all
  end

  def create
    @user_vinyl = UserVinyl.new
    @user_vinyl.save
  end

  def destroy
    @user_vinyl = UserVinyl.find(params[:id])
  end
end
