class UserPartner < ApplicationRecord
  belongs_to :user,    class_name: "User"
  belongs_to :partner, class_name: "User"


  validate :cannot_partner_with_self

  def cannot_partner_with_self
    errors.add(:partner_id, "can't be same as user") if user_id == partner_id
  end
end
