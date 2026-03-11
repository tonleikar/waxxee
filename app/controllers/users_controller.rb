class UsersController < ApplicationController
  def index
    @query = params[:query].to_s.strip
    @users = User.where.not(id: current_user.id).includes(:favorite_vinyl, user_vinyls: :vinyl)
    @users = @users.where("username ILIKE :query OR email ILIKE :query", query: "%#{@query}%") if @query.present?
    @users = @users.order(:username)
    @follows = current_user.active_follows.index_by(&:followed_id)
  end
end
