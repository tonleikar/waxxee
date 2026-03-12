class ProfileController < ApplicationController
  before_action :set_profile_user, only: [:show]
  before_action :ensure_current_user!, only: [:edit, :update, :destroy, :avatar, :avatar_preview]
  before_action :set_current_user, only: [:edit, :update, :destroy, :avatar, :avatar_preview]

  def show
    @vinyls = @user.vinyls
    @favorite_vinyl = @vinyls.find_by(id: @user.favorite_vinyl_id)
    @following_users = @user.following.order(:username)
    @own_profile = @user == current_user
  end

  def edit
    @genres = Vinyl.distinct.order(:genre).pluck(:genre)
  end

  def update
    @user.update!(normalized_profile_params)

    respond_to do |format|
      format.html { redirect_to profile_path(@user) }
      format.json { render json: { success: true, favorite_vinyl_id: @user.favorite_vinyl_id } }
    end
  end

  def avatar
    source_type = if avatar_params[:avatar_file].present?
      "uploaded"
    else
      "generated"
    end

    upload_source = if avatar_params[:avatar_file].present?
      avatar_params[:avatar_file].tempfile
    else
      avatar_params[:avatar_source_url]
    end

    upload = Cloudinary::Uploader.upload(
      upload_source,
      folder: "waxxee/profile_avatars",
      public_id: "user_#{@user.id}_avatar",
      overwrite: true,
      invalidate: true
    )

    @user.update!(avatar_url: upload["secure_url"], avatar_source_type: source_type)

    respond_to do |format|
      format.html { redirect_to edit_profile_path(@user), notice: "Profile picture updated." }
      format.json { render json: { avatar_url: @user.avatar_url, avatar_source_type: @user.avatar_source_type } }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to edit_profile_path(@user), alert: "Could not save profile picture: #{e.message}" }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def avatar_preview
    render json: {
      image_url: fetch_generated_avatar_url
    }
  rescue StandardError => e
    render json: { error: e.message }, status: :bad_gateway
  end

  def destroy
    @user.destroy!
    redirect_to authenticated_root_path
  end

  private

  def set_profile_user
    @user = User.find(params[:id])
  end

  def ensure_current_user!
    return if params[:id].blank? || params[:id].to_s == current_user.id.to_s

    redirect_to profile_path(current_user)
  end

  def set_current_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(:name, :username, :favorite_genre, :avatar_url, :favorite_vinyl_id)
  end

  def avatar_params
    params.require(:user).permit(:avatar_source_url, :avatar_file)
  end

  def normalized_profile_params
    attributes = profile_params
    favorite_id = attributes[:favorite_vinyl_id]

    return attributes if favorite_id.blank?

    unless current_user.vinyls.exists?(id: favorite_id)
      attributes[:favorite_vinyl_id] = nil
    end

    attributes
  end

  def fetch_generated_avatar_url
    uri = URI("https://randomuser.me/api/")
    uri.query = URI.encode_www_form(seed: params[:cb].presence || Time.current.to_i, inc: "picture")

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: 5,
      read_timeout: 15
    ) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Waxxee/1.0"
      http.request(request)
    end

    raise "Avatar generation failed with status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    payload = JSON.parse(response.body)
    image_url = payload.dig("results", 0, "picture", "large")
    raise "Avatar generation returned no image" if image_url.blank?

    image_url
  end
end
