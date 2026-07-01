# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  confirmation_sent_at   :datetime
#  confirmed_at           :datetime
#  created_by             :integer
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string
#  encrypted_password     :string
#  failed_attempts        :integer          default(0), not null
#  first_name             :string           not null
#  identification_number  :string           not null
#  identification_type    :integer          default("nric"), not null
#  invitation_accepted_at :datetime
#  invitation_sent_at     :datetime
#  invitation_token       :string
#  last_name              :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  login_enabled          :boolean          default(FALSE), not null
#  provider               :string
#  remember_created_at    :datetime
#  remember_token         :string
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer          default("family_manager"), not null
#  sign_in_count          :integer          default(0), not null
#  status                 :integer          default("alive"), not null
#  uid                    :string
#  unconfirmed_email      :string
#  unlock_token           :string
#  updated_by             :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  parent_id              :integer
#
# Indexes
#
#  index_users_on_id_type_and_number    (identification_type,identification_number) UNIQUE
#  index_users_on_parent_id             (parent_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
class User < ApplicationRecord
# Remove: include Noticed::Model
# Remove: has_noticed_notifications

# Add this instead:
  has_many :noticed_notifications, as: :recipient, dependent: :destroy, class_name: "Noticed::Notification"
  # ===================================================
  # Activity feed
  include PublicActivity::Model
  tracked owner: :itself
  # ===================================================
  # DEVISE
 devise :database_authenticatable,
       :registerable,
       :recoverable,
       :rememberable,
       :validatable,
       :confirmable
  with_options if: :login_enabled? do
    validates :email, presence: true
    validates :password, presence: true
  end
  devise :omniauthable, omniauth_providers: [:google_oauth2]
  # ===================================================
  # CALLBACKS
  # ===================================================
  after_create :create_default_profile, unless: :user_profile_present?

  # ===================================================
  # ASSOCIATIONS
  # ===================================================
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships
  has_many :life_activities, dependent: :destroy
  # -------------------------
  # PROFILE
  # -------------------------
  has_one :user_profile, dependent: :destroy

  accepts_nested_attributes_for :user_profile, allow_destroy: true

  # -------------------------
  # FAMILY MEMBERSHIPS
  # -------------------------

  has_many :family_memberships,
           dependent: :destroy

  has_many :families,
           through: :family_memberships

  accepts_nested_attributes_for :family_memberships,
                                allow_destroy: true

  # -------------------------
  # PARENT / CHILD RELATIONSHIPS
  # -------------------------
  has_many :parent_relationships,
           class_name: "UserParentRelationship",
           foreign_key: :child_id,
           dependent: :destroy

  has_many :child_relationships,
           class_name: "UserParentRelationship",
           foreign_key: :parent_id,
           dependent: :destroy

  has_many :parents,
           through: :parent_relationships,
           source: :parent

  has_many :children,
           through: :child_relationships,
           source: :child

  # -------------------------
  # PARTNER RELATIONSHIPS
  # -------------------------
  has_many :user_partners,
           class_name: "UserPartner",
           foreign_key: :user_id,
           dependent: :destroy

  has_many :inverse_user_partners,
           class_name: "UserPartner",
           foreign_key: :partner_id,
           dependent: :destroy

  has_many :partners,
           through: :user_partners,
           source: :partner

  has_many :inverse_partners,
           through: :inverse_user_partners,
           source: :user

  # ===================================================
  # ENUMS
  # ===================================================
  enum :role, {
    family_manager: 0,
    viewer: 1,
    admin: 2
  }

  enum :status, {
    alive: 0,
    dead: 1
  }

  enum :identification_type, {
    nric: 0,
    passport: 1,
    driving_license: 2,
    birth_certificate: 3
  }

  # ===================================================
  # SCOPES
  # ===================================================
  scope :with_login, -> { where(login_enabled: true) }
  scope :tree_only,  -> { where(login_enabled: false) }

  # ===================================================
  # VIRTUAL ATTRIBUTES
  # ===================================================
  attr_accessor :new_family_name

  # ===================================================
  # VALIDATIONS
  # ===================================================

  validates :first_name, presence: true
  validates :last_name, presence: true

  validates :identification_number,
            presence: true,
            uniqueness: {
              scope: :identification_type
            }

  validate :cannot_have_more_than_two_families
  # validate :identification_number_format

   def identification_number_format
    return if identification_type.blank? || identification_number.blank?

    case identification_type
    when "nric"
      unless identification_number.match?(/\A\d{6}-\d{2}-\d{4}\z/)
        errors.add(:identification_number, "must be in NRIC format XXXXXX-XX-XXXX")
      end

    when "passport"
      unless identification_number.match?(/\A[A-Z0-9]{6,9}\z/i)
        errors.add(:identification_number, "must be a valid passport number")
      end

    when "driving_license"
      unless identification_number.match?(/\A[A-Z0-9\-]{5,15}\z/i)
        errors.add(:identification_number, "must be a valid driving license number")
      end

    when "birth_certificate"
      unless identification_number.match?(/\A\d{6,20}\z/)
        errors.add(:identification_number, "must be a valid birth certificate number")
      end
    end
  end
def pending_chat_invite_from?(inviter)
  noticed_notifications
    .joins(:event)
    .where(noticed_events: { type: "ChatInviteNotifier" })
    .where(read_at: nil)
    .any? do |notification|
      params = notification.event.params
      params = JSON.parse(params) if params.is_a?(String)
      params["inviter_id"].to_s == inviter.id.to_s
    end
end
  #==============================================
  # DEVISE OVERRIDES
  # ===================================================

  def email_required?
    login_enabled?
  end

  def password_required?
    return false unless login_enabled?

    new_record? || password.present? || password_confirmation.present?
  end

  # ===================================================
  # BUSINESS RULES
  # ===================================================
 def cannot_have_more_than_two_families
  birth_families = families.select { |f| f.family_membership_type == "birth" }
  marriage_families = families.select { |f| f.family_membership_type == "marriage" }

  if birth_families.size > 1
    errors.add(:families, "can only have one birth family")
  end

  if marriage_families.size > 1
    errors.add(:families, "can only have one marriage family")
  end

end

  # ===================================================
  # RANSACK
  # ===================================================
  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      first_name
      last_name
      email
      role
      status
      identification_type
      identification_number
      login_enabled
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[
      user_profile
      families
      family_memberships
      parents
      children
      partners
      inverse_partners
    ]
  end

  # ===================================================
  # CLASS HELPERS
  # ===================================================
  def self.status_options
    statuses.keys.map { |status| [status.humanize, status] }
  end
  def self.identification_type_options
    identification_types.keys.map do |type|
    [type.humanize, type]
    end 
  end
  # ===================================================
  # INSTANCE HELPERS
  # ===================================================
  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def initials
    "#{first_name.to_s.first}#{last_name.to_s.first}".upcase
  end

  def age
    return "-" unless user_profile&.birth_date.present?

    ((Date.current - user_profile.birth_date) / 365.25).floor
  end

  def all_partners
    (partners + inverse_partners).uniq
  end

  def login_user?
    login_enabled?
  end

  def tree_member?
    !login_enabled?
  end


# ===================================================
# INVITATION
# ===================================================
def invite!(invited_by:)
  raw_token               = SecureRandom.urlsafe_base64(32)
  self.invitation_token   = Digest::SHA256.hexdigest(raw_token)
  self.invitation_sent_at = Time.current
  save!(validate: false)
  raw_token
end

def self.find_by_invitation_token(raw_token)
  hashed = Digest::SHA256.hexdigest(raw_token.to_s)
  find_by(invitation_token: hashed)
end

def invitation_token_valid?
  invitation_sent_at.present? && invitation_sent_at > 7.days.ago
end

def accept_invitation!(email:, password:, password_confirmation:, family_code: nil)
  self.email                  = email
  self.password               = password
  self.password_confirmation  = password_confirmation
  self.login_enabled          = true
  self.invitation_token       = nil
  self.invitation_sent_at     = nil
  self.invitation_accepted_at = Time.current

  ActiveRecord::Base.transaction do
    save!(validate: false)
    redeem_family_code!(family_code) if family_code&.redeemable?
  end

  true
rescue ActiveRecord::RecordInvalid => e
  errors.add(:base, e.message)
  false
end

private

def redeem_family_code!(family_code)
  # Mark the code as used
  family_code.mark_used!(self)

  # Create FamilyMembership unless one already exists
  unless family_memberships.exists?(family: family_code.family)
    family_memberships.create!(
      family:          family_code.family,
      membership_type: family_code.membership_type
    )
  end

  # Wire up the relationship to the related user (parent or partner)
  return unless family_code.related_user.present?

  if family_code.birth?
    # related_user is the parent — create parent→child relationship
    unless UserParentRelationship.exists?(parent: family_code.related_user, child: self)
      UserParentRelationship.create!(parent: family_code.related_user, child: self)
    end
  elsif family_code.marriage?
    # related_user is the partner — create partner relationship
    unless UserPartner.exists?(user: family_code.related_user, partner: self) ||
           UserPartner.exists?(user: self, partner: family_code.related_user)
      UserPartner.create!(user: family_code.related_user, partner: self)
    end
  end
end
# ===================================================
# OMNIAUTH
# ===================================================def self.from_omniauth(auth)
def self.from_omniauth(auth)
  user = where(provider: auth.provider, uid: auth.uid).first
  user ||= where(email: auth.info.email).first_or_initialize do |u|
    u.provider = auth.provider
    u.uid = auth.uid
  end

  if user.new_record?
    user.email = auth.info.email
    user.password = Devise.friendly_token[0, 20]
    user.first_name = auth.info.first_name.presence || auth.info.name.to_s.split(" ").first || ""
    user.last_name = auth.info.last_name.presence || auth.info.name.to_s.split(" ").last || ""
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    # Don't save yet — identification fields are required
  end

  user
end

has_many :user_sessions, dependent: :destroy

  def last_active_at
    user_sessions.maximum(:last_active_at)
  end

  def online?
    last_active_at&.> 5.minutes.ago
  end

 
  # ===================================================
  # PRIVATE METHODS
  # ===================================================
  private

  def user_profile_present?
    user_profile.present?
  end

  def create_default_profile
    create_user_profile!(
      birth_date: nil,
      gender: nil,
      marital_status: nil,
      occupation: nil,
      address: nil,
      city: nil,
      state: nil,
      zip: nil,
      country: nil,
      phone: nil,
      nationality: nil
    )
  end
end
