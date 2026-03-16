class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  def home
    redirect_to welcome_index_path if current_user.present?
    @recent_vinyls = Vinyl.last(4)
  end

  def randomizer
    respond_to do |format|
      format.html
      format.json do
        vinyl = current_user.vinyls.sample

        if vinyl.present?
          render json: vinyl_payload(vinyl)
        else
          render json: { error: "No vinyl found." }, status: :not_found
        end
      end
    end
  end

  private

  def vinyl_payload(vinyl)
    saved = current_user.user_vinyls.exists?(vinyl_id: vinyl.id)

    {
      id: vinyl.id,
      title: vinyl.title,
      artist: vinyl.artist,
      year: vinyl.year,
      genre: vinyl.genre,
      format: vinyl.format,
      tracks: Array(vinyl.tracks),
      artwork_url: vinyl.artwork_url,
      saved: saved
    }
  end
end
