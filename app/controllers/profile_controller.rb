class ProfileController < ApplicationController
  def show
    @user = current_user
    @favorite_vinyl = current_user.favorite_vinyl
    @vinyls = current_user.vinyls
  end

  def edit
    @user = current_user
    @favorite_vinyl = current_user.favorite_vinyl
    @vinyls = current_user.vinyls
    @genres = Vinyl.distinct.order(:genre).pluck(:genre)
  end

  def update
    @user = current_user
    @user.update!(profile_params)
    redirect_to profile_path(@user)
  end

  def destroy
    current_user.destroy!
    redirect_to root_path
  end

  private

  def profile_params
    params.require(:user).permit(:name, :username, :favorite_genre, :avatar_url, :favorite_vinyl_id)
  end
end
