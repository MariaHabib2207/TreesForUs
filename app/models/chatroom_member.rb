# == Schema Information
#
# Table name: chatroom_members
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  chatroom_id :integer
#  user_id     :integer
#
class ChatroomMember < ApplicationRecord
  belongs_to :chatroom
  belongs_to :user
end
