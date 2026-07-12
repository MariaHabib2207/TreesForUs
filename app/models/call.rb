class Call < ApplicationRecord
  belongs_to :chatroom
  belongs_to :caller, class_name: "User"
  belongs_to :callee, class_name: "User"
  has_one :message, dependent: :nullify
  has_many :call_hidings, dependent: :destroy

  enum :call_type, { audio: "audio", video: "video" }
  enum :status, { missed: "missed", declined: "declined", answered: "answered", busy: "busy" }

  validates :duration_in_seconds, numericality: { greater_than_or_equal_to: 0 }

  # Only logged by the caller's browser (see call_session.js), so a call
  # between two people produces exactly one row, not two.
  scope :involving, ->(user) { where("caller_id = :id OR callee_id = :id", id: user.id) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :visible_to, ->(user) { where.not(id: CallHiding.where(user: user).select(:call_id)) }

  def other_party(current_user)
    caller_id == current_user.id ? callee : caller
  end

  def outgoing?(current_user)
    caller_id == current_user.id
  end

  def hidden_for?(user)
    call_hidings.exists?(user_id: user.id)
  end

  # "Delete" for the call log feature — hides the row for this user only.
  # Never destroys the underlying Call or its chat message.
  def hide_for(user)
    call_hidings.find_or_create_by(user: user)
  end

  def formatted_duration
    return nil if duration_in_seconds.to_i <= 0
    minutes = duration_in_seconds / 60
    seconds = duration_in_seconds % 60
    format("%d:%02d", minutes, seconds)
  end
end
