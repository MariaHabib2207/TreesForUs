# == Schema Information
#
# Table name: chatrooms
#
#  id            :integer          not null, primary key
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :integer
#
class Chatroom < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :chatroom_members, dependent: :destroy
  has_many :members, through: :chatroom_members, source: :user
  has_many :messages, dependent: :destroy

  def self.between(user1, user2)
    joins(:chatroom_members)
      .where(chatroom_members: { user_id: user1.id })
      .joins(:chatroom_members)
      .where(chatroom_members: { user_id: user2.id })
      .first
  end
end
