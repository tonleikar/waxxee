class UserVinylsController < ApplicationController
  def index
    @user_vinyls = UserVinyl.all
  end

  def create
    return render json: { error: "Missing release_id." }, status: :unprocessable_entity if release_id.blank?

    vinyl = Discogs::ReleaseImporter.new.import!(
      release_id: release_id,
      cover_image: cover_image
    )
    @user_vinyl = current_user.user_vinyls.find_by(vinyl: vinyl)
    created = false

    unless @user_vinyl
      @user_vinyl = UserVinyl.create!(user: current_user, vinyl: vinyl)
      created = true
      refresh_primary_persona
    end

    render json: {
      id: @user_vinyl.id,
      vinyl_id: vinyl.id,
      saved: true,
      persona_updated: created,
      message: "#{@user_vinyl.vinyl.title.truncate(25, omission: '...')} added to collection."
    }, status: :created
  rescue Discogs::ConfigurationError, Discogs::ApiError, ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    @user_vinyl = current_user.user_vinyls.find(params[:id])
    current_user.update!(favorite_vinyl_id: nil) if current_user.favorite_vinyl_id == @user_vinyl.vinyl_id
    @user_vinyl.destroy!
    redirect_back fallback_location: vinyls_path, notice: "Vinyl removed from collection."
  end

  private

  def release_id
    params[:release_id].presence || params.dig(:vinyl, :id).presence
  end

  def cover_image
    params[:cover_image].presence || params.dig(:vinyl, :cover_image).presence
  end

  def refresh_primary_persona
    PersonaUpdater.new(user: current_user, primary_profile: true).call
  rescue StandardError => e
    Rails.logger.warn("Persona refresh failed for user #{current_user.id}: #{e.message}")
  end

end
