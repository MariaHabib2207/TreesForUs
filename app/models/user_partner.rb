# == Schema Information
#
# Table name: user_partners
#
#  id         :integer          not null, primary key
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  partner_id :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_user_partners_on_deleted_at              (deleted_at)
#  index_user_partners_on_partner_id              (partner_id)
#  index_user_partners_on_user_id                 (user_id)
#  index_user_partners_on_user_id_and_partner_id  (user_id,partner_id) UNIQUE
#
# Foreign Keys
#
#  partner_id  (partner_id => users.id)
#  user_id     (user_id => users.id)
#
class UserPartner < ApplicationRecord
  acts_as_paranoid



  belongs_to :user, class_name: "User"
  belongs_to :partner, class_name: "User"

  accepts_nested_attributes_for :partner
  validate :cannot_partner_with_self

  def cannot_partner_with_self
    errors.add(:partner_id, "can't be same as user") if user_id == partner_id
  end
end
