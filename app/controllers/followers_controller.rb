class FollowersController < ApplicationController
  def index
    @users = current_user.following.includes(:favorite_vinyl, user_vinyls: :vinyl)
    @users = @users.where("username ILIKE ?", "%#{params[:query]}%") if params[:query].present?
    @vinyls = @users.flat_map(&:vinyls)
    @follows = current_user.active_follows.index_by(&:followed_id)
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
