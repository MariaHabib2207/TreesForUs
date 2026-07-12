class CallHiding < ApplicationRecord
  belongs_to :call
  belongs_to :user

  validates :user_id, uniqueness: { scope: :call_id }
end
