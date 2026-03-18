class PersonasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_return_path, only: %i[create destroy]

  def create
    persona = PersonaUpdater.new(
      user: current_user,
      prompt: persona_params[:prompt],
      primary_profile: primary_profile_request?
    ).call
    puts "Creating Persona #{params}"
    redirect_to next_path_for(persona), notice: persona_notice
  rescue StandardError => e
    redirect_to @return_path, alert: "Could not generate persona: #{e.message}"
  end

  def destroy
    persona = current_user.personas.find(params[:id])
    persona.destroy!

    redirect_to @return_path, notice: "Persona removed."
  end

  private

  def persona_params
    params.fetch(:persona, {}).permit(:prompt, :primary_profile, :return_to, :redirect_to_swiper)
  end

  def primary_profile_request?
    ActiveModel::Type::Boolean.new.cast(persona_params[:primary_profile]) == true
  end

  def set_return_path
    @return_path = safe_return_path || profile_path(current_user)
  end

  def safe_return_path
    return if persona_params[:return_to].blank?

    uri = URI.parse(persona_params[:return_to])
    return if uri.host.present? || uri.scheme.present?

    uri.to_s
  rescue URI::InvalidURIError
    nil
  end

  def persona_notice
    primary_profile_request? ? "Your Waxxee persona was updated." : "Custom persona created."
  end

  def next_path_for(persona)
    return swiper_index_path(persona_id: persona.id) if redirect_to_swiper?

    @return_path
  end

  def redirect_to_swiper?
    ActiveModel::Type::Boolean.new.cast(persona_params[:redirect_to_swiper]) == true
  end
end
