class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    permitted = %i[name username favorite_genre]
    devise_parameter_sanitizer.permit(:sign_up, keys: permitted)
    devise_parameter_sanitizer.permit(:account_update, keys: permitted)
  end
end
