class FollowersController < ApplicationController
  def index
    @users = User.where.not(id: current_user.id).includes(:favorite_vinyl, user_vinyls: :vinyl)
    @users = @users.where("username ILIKE ?", "%#{params[:query]}%")
    @users = @users.sample(5) if params[:query].blank?
    @vinyls = @users.flat_map(&:vinyls)
    @follows = current_user.active_follows.index_by(&:followed_id)
  end

  def create
    Follower.create!(follower: current_user, followed_id: params[:followed_id])
    redirect_to feed_index_path
  end

  def destroy
    follower = current_user.active_follows.find(params[:id])
    follower.destroy!
    redirect_to feed_index_path
  end
end
