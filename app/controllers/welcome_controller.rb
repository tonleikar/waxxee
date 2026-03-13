class WelcomeController < ApplicationController
  def index
    @recent_vinyls = UserVinyl.last(4)
    @user = current_user
    @saved_personas = current_user.personas.where(primary_profile: false).order(created_at: :desc)
    @persona_builder_label = @saved_personas.any? ? "Create Next Persona" : "Create your own persona"

    @personas = Persona.all
  end
end
