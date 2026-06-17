class FamilyCode < ApplicationRecord
  belongs_to :family
  belongs_to :created_by,   class_name: "User"
  belongs_to :used_by,      class_name: "User", optional: true
  belongs_to :related_user, class_name: "User", optional: true  # parent or partner

  enum :membership_type, FamilyMembership.membership_types

  validates :code,            presence: true, uniqueness: true
  validates :email,           presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :expires_at,      presence: true
  validates :membership_type, presence: true

  # For birth: related_user is the parent. For marriage: related_user is the partner.
  validates :related_user, presence: true, if: -> { birth? || marriage? }

  before_validation :generate_code, on: :create

  scope :valid,   -> { where(used_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :used,    -> { where.not(used_at: nil) }

  def expired?    = expires_at <= Time.current
  def used?       = used_at.present?
  def redeemable? = !used? && !expired?

  def mark_used!(user)
    update!(used_at: Time.current, used_by: user)
  end

  # Human-readable label for the related_user's role
  def related_user_role
    return nil unless related_user
    birth? ? "Parent" : "Partner"
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(8).upcase
  end
end