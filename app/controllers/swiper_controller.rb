class SwiperController < ApplicationController
  def index
    @key = ENV.fetch("DISCOGS_CONSUMER_KEY", nil)
    @secret = ENV.fetch("DISCOGS_CONSUMER_SECRET", nil)
  end

  def card_preview
    vinyl = Discogs::SearchResult.new(vinyl_payload).preview_attributes
    render partial: "swiper/vinyl_card", locals: { vinyl: vinyl }
  end

  private

  def vinyl_payload
    params.require(:vinyl).permit!.to_h
    @persona_key = selected_persona_key || "randomizer"
    @persona = Persona::RULES.fetch(@persona_key)
    @vinyls = filtered_vinyl_scope(@persona).to_a.sample(20)
    @user_vinyl = UserVinyl.new
  end

  def filtered_vinyl_scope(persona)
    scope = Vinyl.where(year: persona[:min_year]..persona[:max_year])

    return scope if persona[:genres] == [""]

    scope.where(
      persona[:genres].map { "genre ILIKE ?" }.join(" OR "),
      *persona[:genres].map { |genre| "%#{genre}%" }
    )
  end

  def selected_persona_key
    key = params[:persona]&.downcase
    key if key.present? && Persona::RULES.key?(key)
  end
end
