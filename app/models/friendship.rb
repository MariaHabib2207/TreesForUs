
class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :friend_id, uniqueness: { scope: :user_id }
  validate  :cannot_friend_self

  private

  def cannot_friend_self
    errors.add(:friend_id, "can't be yourself") if user_id == friend_id
  end
end