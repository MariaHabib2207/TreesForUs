
# == Schema Information
#
# Table name: friendships
#
#  id         :integer          not null, primary key
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  friend_id  :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_friendships_on_deleted_at             (deleted_at)
#  index_friendships_on_friend_id              (friend_id)
#  index_friendships_on_user_id                (user_id)
#  index_friendships_on_user_id_and_friend_id  (user_id,friend_id) UNIQUE
#
# Foreign Keys
#
#  friend_id  (friend_id => users.id)
#  user_id    (user_id => users.id)
#
class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :friend_id, uniqueness: { scope: :user_id }
  validate  :cannot_friend_self
  acts_as_paranoid


  private

  def cannot_friend_self
    errors.add(:friend_id, "can't be yourself") if user_id == friend_id
  end
end
