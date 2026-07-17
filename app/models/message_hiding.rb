# == Schema Information
#
# Table name: message_hidings
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  message_id :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_message_hidings_on_message_id              (message_id)
#  index_message_hidings_on_message_id_and_user_id  (message_id,user_id) UNIQUE
#  index_message_hidings_on_user_id                 (user_id)
#
# Foreign Keys
#
#  message_id  (message_id => messages.id)
#  user_id     (user_id => users.id)
#
class MessageHiding < ApplicationRecord
  belongs_to :message
  belongs_to :user
end
