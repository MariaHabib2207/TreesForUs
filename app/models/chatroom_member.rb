# == Schema Information
#
# Table name: chatroom_members
#
#  id              :integer          not null, primary key
#  content_blurred :boolean          default(FALSE), not null
#  deleted_at      :datetime
#  hidden_at       :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  chatroom_id     :integer
#  user_id         :integer
#
# Indexes
#
#  index_chatroom_members_on_deleted_at  (deleted_at)
#  index_chatroom_members_on_hidden_at   (hidden_at)
#
class ChatroomMember < ApplicationRecord
  belongs_to :chatroom
  belongs_to :user
  acts_as_paranoid
end
