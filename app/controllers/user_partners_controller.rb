class UserPartnersController < ApplicationController
  before_action :set_user
  before_action :set_active_family

  def new
    @user_partner = UserPartner.new
    load_available_users
  end

  def create
    @user_partner = nil
    avatar = nil

    ActiveRecord::Base.transaction do
      partner, avatar = find_or_create_partner!

      @user_partner = UserPartner.create!(
        user:    @user,
        partner: partner
      )

      FamilyMembership.find_or_create_by!(
        user:            partner,
        family:          @active_family,
        membership_type: params[:membership_type].presence || "marriage"
      )
    end
    if avatar.present?
      @user_partner.partner.user_profile.avatar.attach(avatar)
    end

    redirect_to authenticated_root_path, notice: "Spouse added successfully."

  rescue ActiveRecord::RecordInvalid => e
    @user_partner ||= UserPartner.new
    @user_partner.errors.add(:base, e.record&.errors&.full_messages&.to_sentence || e.message)
    load_available_users
    render :new, status: :unprocessable_entity
  end


  def find_or_create_partner!
    if user_partner_params[:partner_id].present?
      return [User.find(user_partner_params[:partner_id]), nil]
    end

    p_attrs       = safe_partner_params
    login_enabled = raw_login_enabled

    if p_attrs[:first_name].blank? && p_attrs[:last_name].blank?
      up = UserPartner.new
      up.errors.add(:base, "Please select an existing spouse or fill in the new spouse details.")
      raise ActiveRecord::RecordInvalid.new(up)
    end

    user_attrs = {
      first_name:            p_attrs[:first_name],
      last_name:             p_attrs[:last_name],
      identification_type:   p_attrs[:identification_type],
      identification_number: p_attrs[:identification_number],
      status:                p_attrs[:status].presence || "alive",
      login_enabled:         login_enabled,
      role:                  login_enabled ? "family_manager" : "viewer"
    }

    if login_enabled
      user_attrs[:email]                 = p_attrs[:email]
      user_attrs[:password]              = p_attrs[:password]
      user_attrs[:password_confirmation] = p_attrs[:password_confirmation]
    end

    partner = User.new(user_attrs)
    Rails.logger.debug "=== partner attributes before save ==="
    Rails.logger.debug user_attrs.inspect
    Rails.logger.debug "=== partner valid? #{partner.valid?} ==="
    Rails.logger.debug "=== partner errors: #{partner.errors.full_messages} ==="
    partner.save!
    partner.save!

    profile_attrs = safe_partner_profile_params.to_h
    raw_avatar    = profile_attrs.delete("avatar")
    avatar        = raw_avatar.is_a?(ActionDispatch::Http::UploadedFile) ? raw_avatar : nil

    # Ensure profile exists before updating
    profile = partner.user_profile || partner.create_user_profile!
    profile.update!(profile_attrs) if profile_attrs.any?

    [partner, avatar]
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_active_family
    @active_family = Family.find_by(id: params[:family_id]) ||
                     @user.families.first
  end

  def load_available_users
    @available_users = User
      .joins(:family_memberships)
      .where(family_memberships: {
        family_id:       @active_family&.id,
        membership_type: "marriage"
      })
      .where.not(id: @user.id)
      .distinct
  end

  def user_partner_params
    params.require(:user_partner).permit(:partner_id)
  end

  def safe_partner_params
    params.fetch(:partner, {}).permit(
      :first_name,
      :last_name,
      :email,
      :password,
      :password_confirmation,
      :identification_type,
      :identification_number,
      :status
    )
  end

  def safe_partner_profile_params

    permitted = params.fetch(:partner, {}).permit(
      user_profile_attributes: %i[
        birth_date
        gender
        phone
        occupation
        address
        avatar
      ]
    )
    permitted[:user_profile_attributes] || {}
  end

  # Read separately — never mass-assigned into User.new
  def raw_login_enabled
    ActiveModel::Type::Boolean.new.cast(
      params.dig(:partner, :login_enabled)
    ) || false
  end
end