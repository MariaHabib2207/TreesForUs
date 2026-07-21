class InvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invitee
  before_action :set_target_family

  def new
    # Derive membership_type and related_user from URL params set by the tree
    @membership_type = case params[:type]
    when "partner" then "marriage"
    when "friend"   then "friend"
    else "birth"
    end
    @related_user    = User.find_by(id: params[:related_user_id])
  end

  def create
    if @invitee.login_enabled?
      return respond_with_error("#{@invitee.first_name} already has app access.")
    end

    email           = params.dig(:invitation, :email).to_s.strip
    membership_type = params.dig(:invitation, :membership_type).to_s.strip
    related_user_id = params.dig(:invitation, :related_user_id).to_s.strip

    @invitee.errors.add(:base, "Email can't be blank") if email.blank?

    unless FamilyCode.membership_types.key?(membership_type)
      @invitee.errors.add(:base, "Please select a membership type")
    end

    if @invitee.errors.any?
      @membership_type = membership_type
      @related_user    = User.find_by(id: related_user_id)
      return render :new, status: :unprocessable_entity
    end

    family_code = FamilyCode.create!(
      family:          @target_family,
      created_by:      current_user,
      membership_type: membership_type,
      email:           email,
      expires_at:      7.days.from_now,
      related_user_id: related_user_id.presence
    )

    raw_token = @invitee.invite!(invited_by: current_user)
    InvitationMailer.invite(@invitee, raw_token, email, family_code).deliver_now

    redirect_to authenticated_root_path, notice: "Invitation sent to #{email}!"
  end

  def cancel
  invitee = User.find(params[:user_id])

  FamilyCode.where(related_user_id: invitee.id).destroy_all
  invitee.update_columns(invitation_token: nil, invitation_sent_at: nil)

  redirect_to authenticated_root_path, notice: "Invitation to #{invitee.first_name} was cancelled."
end
  private

  def set_invitee
    @invitee = User.find(params[:user_id])
  end

  def set_target_family
    related_user   = User.find_by(id: params[:related_user_id])
    invitee_family = @invitee.families.first
    related_family = related_user&.families&.first

    @target_family = related_family || invitee_family

    unless @target_family && current_user.families.include?(@target_family)
      redirect_to root_path, alert: "Not authorized."
    end
  end

  def respond_with_error(msg)
    redirect_back fallback_location: root_path, alert: msg
  end
end
