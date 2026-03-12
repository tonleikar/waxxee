class PagesController < ApplicationController
  def home_logged_in
    @personas = Persona::RULES.map do |key, rule|
      next if key == "randomizer"

      {
        key: key,
        title: rule[:title],
        min_year: rule[:min_year],
        max_year: rule[:max_year],
        genres: rule[:genres]
      }
    end.compact
    @persona_key = selected_persona_key || "randomizer"
    @persona = Persona::RULES.fetch(@persona_key)

    respond_to do |format|
      format.html
      format.json do
        vinyl = random_vinyl_for_persona(@persona)

        if vinyl.present?
          render json: vinyl_payload(vinyl)
        else
          render json: { error: "No vinyl found." }, status: :not_found
        end
      end
    end
  end

  private

  def random_vinyl_for_persona(persona)
    Vinyl
      .where(year: persona[:min_year]..persona[:max_year])
      .where(
        persona[:genres].map { "genre ILIKE ?" }.join(" OR "),
        *persona[:genres].map { |genre| "%#{genre}%" }
      ).sample
  end

  def selected_persona_key
    key = params[:persona]&.downcase
    key if key.present? && Persona::RULES.key?(key)
  end

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
