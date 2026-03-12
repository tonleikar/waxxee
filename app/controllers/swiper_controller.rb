class SwiperController < ApplicationController
  include PersonaVinylPicker

  def index
    @key = ENV.fetch("DISCOGS_CONSUMER_KEY", nil)
    @secret = ENV.fetch("DISCOGS_CONSUMER_SECRET", nil)
    vinyl_payload
  end

  def card_preview
    vinyl = Discogs::SearchResult.new(params[:vinyl]).preview_attributes
    render partial: "swiper/vinyl_card", locals: { vinyl: vinyl }
  end

  private

  def vinyl_payload
    params.require(:vinyl).permit!.to_h if params[:vinyl].present?
    @persona_record = selected_persona_record
    @persona_key = selected_persona_key || "randomizer"
    @persona = @persona_record&.picker_rule || Persona::RULES.fetch(@persona_key)
    @vinyls = filtered_vinyl_scope(@persona).to_a.sample(20)
    @user_vinyl = UserVinyl.new
  end

  def selected_persona_key
    key = params[:persona]&.downcase
    key if key.present? && Persona::RULES.key?(key)
  end

  def selected_persona_record
    return if params[:persona_id].blank?

    Persona.find_by(id: params[:persona_id])
  end
end
