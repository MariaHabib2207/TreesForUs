
class IdentificationController < ApplicationController
  before_action :load_google_data, only: [ :edit, :update ]

  def edit
    @user = User.new(
      email: @google_data["email"],
      first_name: @google_data["first_name"],
      last_name: @google_data["last_name"]
    )
  end

  def update
    @user = User.new(
      email: @google_data["email"],
      password: @google_data["password"],
      first_name: params[:user][:first_name],
      last_name: params[:user][:last_name],
      provider: @google_data["provider"],
      uid: @google_data["uid"],
      identification_type: params[:user][:identification_type],
      identification_number: params[:user][:identification_number]
    )
    @user.skip_confirmation!

    if @user.save
      session.delete("devise.google_data")
      flash[:notice] = "Welcome! You have signed in with Google."
      sign_in_and_redirect @user, event: :authentication
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_google_data
    @google_data = session["devise.google_data"]
    if @google_data.blank?
      redirect_to new_user_session_path, alert: "Session expired, please try again."
    end
  end
end
