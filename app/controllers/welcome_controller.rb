class WelcomeController < ApplicationController
  def index
    @recent_vinyls = UserVinyl.last(4)
    @user = current_user
    @premade_personas = Persona.where(user_id: nil).order(created_at: :desc).limit(3)
    @saved_personas = current_user.personas.where(primary_profile: false).order(created_at: :desc)

    @personas = Persona.all
    @staff_picks = @personas.where(staff_pick: true)
  end
end
