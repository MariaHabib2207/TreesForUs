# == Schema Information
#
# Table name: chatrooms
#
#  id            :integer          not null, primary key
#  deleted_at    :datetime
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :integer
#
# Indexes
#
#  index_chatrooms_on_deleted_at  (deleted_at)
#
class Chatroom < ApplicationRecord
  belongs_to :created_by, class_name: "User"
  has_many :chatroom_members, dependent: :destroy
  has_many :members, through: :chatroom_members, source: :user
  has_many :messages, dependent: :destroy
  acts_as_paranoid


  def self.between(user1, user2)
    joins(:chatroom_members)
      .where(chatroom_members: { user_id: user1.id })
      .joins(:chatroom_members)
      .where(chatroom_members: { user_id: user2.id })
      .first
  end
    def broadcast_system_message(user:, body:)
    message = messages.create!(user: user, body: body, message_type: "system")

    html = ApplicationController.render(
      partial: "messages/message",
      locals: { message: message, current_user_id: nil }
    )

    members.each do |member|
      ActionCable.server.broadcast(
        "chatroom_#{id}_user_#{member.id}",
        { message_html: html, sender_id: message.user_id }
      )
    end

    message
  end

  # Friends not already in this chatroom -> candidates for "Add people"
 def available_friends_for(user)
    friend_ids = Friendship.where(user_id: user.id).pluck(:friend_id) +
                 Friendship.where(friend_id: user.id).pluck(:user_id)

    family_ids = FamilyMembership.where(user_id: user.id).pluck(:family_id)
    family_member_ids = FamilyMembership.where(family_id: family_ids)
                                        .where.not(user_id: user.id)
                                        .pluck(:user_id)

    candidate_ids = (friend_ids + family_member_ids).uniq
    member_ids = members.pluck(:id)

    User.where(id: candidate_ids).where.not(id: member_ids)
  end
end
