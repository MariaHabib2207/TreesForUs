class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    Rails.logger.debug "OMNIAUTH ENV: #{request.env['omniauth.auth'].inspect}"
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Google") if is_navigational_format?
    else
      session["devise.google_data"] = {
        "provider"   => auth.provider,
        "uid"        => auth.uid,
        "email"      => auth.info.email,
        "first_name" => auth.info.first_name.presence || auth.info.name.to_s.split(" ").first || "",
        "last_name"  => auth.info.last_name.presence || auth.info.name.to_s.split(" ").last || "",
        "password"   => Devise.friendly_token[0, 20]
      }
      redirect_to edit_identification_path
    end
  end

  def failure
    redirect_to new_user_session_path, alert: "Authentication failed, please try again."
  end
end
