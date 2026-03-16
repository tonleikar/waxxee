class VinylsController < ApplicationController
  def index
    @query = params[:query].to_s.strip
    @sort = permitted_sort

    @vinyls = Vinyl.where(id: current_user.user_vinyls.select(:vinyl_id))
    if @query.present?
      @vinyls = @vinyls.where(
        "vinyls.title ILIKE :query OR vinyls.artist ILIKE :query OR vinyls.genre ILIKE :query",
        query: "%#{@query}%"
      )
    end

    @vinyls = @vinyls.order(order_clause_for(@sort))
    @folders = current_user.folders.order(name: :asc)
    @user_vinyls_by_vinyl_id = current_user.user_vinyls.includes(:folders, :folder_vinyls).index_by(&:vinyl_id)
  end

  def show
    @vinyl = Vinyl.where(id: current_user.user_vinyls.select(:vinyl_id)).find(params[:id])
  end

  def create
    @vinyl = Vinyl.new
    @vinyl.save
  end

  private

  def permitted_sort
    if %w[title_desc title_asc artist_asc artist_desc year_desc
          year_asc].include?(params[:sort])
      params[:sort]
    else
      "recent"
    end
  end

  def order_clause_for(sort)
    case sort
    when "title_desc"
      { title: :desc }
    when "title_asc"
      { title: :asc }
    when "artist_asc"
      { artist: :asc, title: :asc }
    when "artist_desc"
      { artist: :desc, title: :desc }
    when "year_desc"
      { year: :desc, title: :desc }
    when "year_asc"
      { year: :asc, title: :asc }
    else
      recent_order_clause
    end
  end

  def recent_order_clause
    user_id = ActiveRecord::Base.connection.quote(current_user.id)

    Arel.sql(<<~SQL.squish)
      (
        SELECT MAX(user_vinyls.created_at)
        FROM user_vinyls
        WHERE user_vinyls.user_id = #{user_id}
          AND user_vinyls.vinyl_id = vinyls.id
      ) DESC,
      vinyls.title ASC
    SQL
  end

  def vinyl_params
    params.require(:vinyl).permit(:artist, :artwork_url, :discogs_url, :format, :genre, :year)
  end
end
