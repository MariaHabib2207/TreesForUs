# == Schema Information
#
# Table name: call_hidings
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  call_id    :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_call_hidings_on_call_id              (call_id)
#  index_call_hidings_on_call_id_and_user_id  (call_id,user_id) UNIQUE
#  index_call_hidings_on_user_id              (user_id)
#
# Foreign Keys
#
#  call_id  (call_id => calls.id)
#  user_id  (user_id => users.id)
#
class CallHiding < ApplicationRecord
  belongs_to :call
  belongs_to :user

  validates :user_id, uniqueness: { scope: :call_id }
end
