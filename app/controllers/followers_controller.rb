class FollowersController < ApplicationController
  def index
    @feed_items = UserVinyl
      .where(user: current_user.following)
      .includes(:vinyl, :user)
      .order(created_at: :desc)
  end

  def create
    Follower.create!(follower: current_user, followed_id: params[:followed_id])
    redirect_back fallback_location: users_path
  end

  def destroy
    follower = current_user.active_follows.find(params[:id])
    follower.destroy!
    redirect_back fallback_location: users_path
  end
end
