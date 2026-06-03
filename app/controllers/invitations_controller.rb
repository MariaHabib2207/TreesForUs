# app/controllers/invitations_controller.rb
class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitee

  def new
  end

  def create
    if @invitee.login_enabled?
      return respond_with_error("#{@invitee.first_name} already has app access.")
    end

    email = params.dig(:invitation, :email).to_s.strip

    if email.blank?
      @invitee.errors.add(:email, "can't be blank")
      return render :new, status: :unprocessable_entity
    end

    raw_token = @invitee.invite!(invited_by: current_user)
    Rails.logger.info "Mailer delivery: #{ActionMailer::Base.delivery_method}"
    InvitationMailer.invite(@invitee, raw_token, email).deliver_now
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("modal", "")
      end
      format.html do
        redirect_back fallback_location: dashboard_index_path,
                      notice: "Invitation sent to #{email}!"
      end
    end
  end

  private

  def set_invitee
    @invitee = User.find(params[:user_id])

    unless current_user.admin? || current_user.family_manager?
      redirect_to root_path, alert: "Not authorized."
    end
  end

  def respond_with_error(msg)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "flash",
          partial: "shared/flash",
          locals: { message: msg, type: :alert }
        )
      end
      format.html { redirect_back fallback_location: root_path, alert: msg }
    end
  end
end