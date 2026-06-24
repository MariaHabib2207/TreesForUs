# == Schema Information
#
# Table name: family_memberships
#
#  id              :integer          not null, primary key
#  membership_type :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  family_id       :integer          not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_family_memberships_on_family_id  (family_id)
#  index_family_memberships_on_user_id    (user_id)
#
# Foreign Keys
#
#  family_id  (family_id => families.id)
#  user_id    (user_id => users.id)

class FamilyMembership < ApplicationRecord
  belongs_to :user
  belongs_to :family

  enum :membership_type, {
    birth: 0,
    marriage: 1,
    friend: 2
  }

  validates :user_id, uniqueness: { scope: :family_id, message: "is already associated with this family" }
  validates :membership_type, presence: true

  after_create_commit :notify_existing_family_members

  def self.family_memberships_type_options
    membership_types.keys.map { |membership| [membership.humanize, membership] }
  end

  private

  def notify_existing_family_members
    existing_members = User
      .joins(:family_memberships)
      .where(family_memberships: { family_id: family_id })
      .where.not(id: user_id)

    return if existing_members.empty?

    existing_members.each do |member|
      already_notified = member.noticed_notifications
                               .where(read_at: nil)
                               .joins(:event)
                               .where(noticed_events: { type: "NewFamilyMemberNotifier" })
                               .where("noticed_notifications.created_at > ?", 10.minutes.ago)
                               .exists?
      next if already_notified

      ::NewFamilyMemberNotifier.with(
        message: "#{user.full_name} joined your family \"#{family.name}\"."
      ).deliver(member)
    end
  end
end