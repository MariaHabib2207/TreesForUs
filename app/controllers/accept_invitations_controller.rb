# app/controllers/accept_invitations_controller.rb
class AcceptInvitationsController < ApplicationController
  before_action :load_invitee

  # GET /accept_invitation?token=RAW_TOKEN&family_code=XXXX
  def edit
  end

  # PATCH /accept_invitation?token=RAW_TOKEN&family_code=XXXX
  def update
    family_code = FamilyCode.valid.find_by(code: params[:family_code])

    if @invitee.accept_invitation!(
      email:                 accept_params[:email],
      password:              accept_params[:password],
      password_confirmation: accept_params[:password_confirmation],
      family_code:           family_code
    )
      sign_in(@invitee)
      redirect_to root_path, notice: "Welcome, #{@invitee.first_name}! Your account is now active."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def load_invitee
    raw_token = params[:token].to_s.strip

    if raw_token.blank?
      return redirect_to root_path, alert: "Missing invitation token."
    end

    @invitee = User.find_by_invitation_token(raw_token)

    unless @invitee&.invitation_token_valid?
      redirect_to root_path, alert: "This invitation link is invalid or has expired."
    end
  end

  def accept_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
