class ProfileController < ApplicationController
  before_action :set_profile_user, only: [:show]
  before_action :ensure_current_user!, only: [:edit, :update, :destroy]

  def show
    @vinyls = @user.vinyls
    @favorite_vinyl = @vinyls.find_by(id: @user.favorite_vinyl_id)
    @following_users = @user.following.order(:username)
    @own_profile = @user == current_user
  end

  def edit
    @user = current_user
    @genres = Vinyl.distinct.order(:genre).pluck(:genre)
  end

  def update
    @user = current_user
    @user.update!(normalized_profile_params)

    respond_to do |format|
      format.html { redirect_to profile_path(@user) }
      format.json { render json: { success: true, favorite_vinyl_id: @user.favorite_vinyl_id } }
    end
  end

  def destroy
    current_user.destroy!
    redirect_to authenticated_root_path
  end

  private

  def set_profile_user
    @user = User.find(params[:id])
  end

  def ensure_current_user!
    return if params[:id].blank? || params[:id].to_s == current_user.id.to_s

    redirect_to profile_path(current_user)
  end

  def profile_params
    params.require(:user).permit(:name, :username, :favorite_genre, :avatar_url, :favorite_vinyl_id)
  end

  def normalized_profile_params
    attributes = profile_params
    favorite_id = attributes[:favorite_vinyl_id]

    return attributes if favorite_id.blank?

    unless current_user.vinyls.exists?(id: favorite_id)
      attributes[:favorite_vinyl_id] = nil
    end

    attributes
  end
end
