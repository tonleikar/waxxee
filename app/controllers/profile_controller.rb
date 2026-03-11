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
    upload = Cloudinary::Uploader.upload(
      avatar_params[:avatar_image_data],
      folder: "waxxee/profile_avatars",
      public_id: "user_#{@user.id}_avatar",
      overwrite: true,
      invalidate: true
    )

    @user.update!(avatar_url: upload["secure_url"])

    respond_to do |format|
      format.html { redirect_to edit_profile_path(@user), notice: "Profile picture updated." }
      format.json { render json: { avatar_url: @user.avatar_url } }
    end
  rescue StandardError => e
    respond_to do |format|
      format.html { redirect_to edit_profile_path(@user), alert: "Could not save profile picture: #{e.message}" }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  def avatar_preview
    image_body, content_type = fetch_generated_avatar

    render json: {
      image_data: "data:#{content_type};base64,#{Base64.strict_encode64(image_body)}"
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
    params.require(:user).permit(:avatar_image_data)
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

  def fetch_generated_avatar
    uri = URI("https://thispersondoesnotexist.com/")
    uri.query = URI.encode_www_form(cb: params[:cb].presence || Time.current.to_i)

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

    [response.body, response["Content-Type"].presence || "image/jpeg"]
  end
end
