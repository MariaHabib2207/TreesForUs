# == Schema Information
#
# Table name: messages
#
#  id                         :integer          not null, primary key
#  body                       :text
#  deleted_at                 :datetime
#  deleted_for_everyone_at    :datetime
#  duration_in_seconds        :integer
#  message_type               :string           default("text"), not null
#  read_at                    :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  call_id                    :integer
#  chatroom_id                :integer
#  deleted_for_everyone_by_id :integer
#  user_id                    :integer
#
# Indexes
#
#  index_messages_on_call_id                     (call_id)
#  index_messages_on_deleted_at                  (deleted_at)
#  index_messages_on_deleted_for_everyone_by_id  (deleted_for_everyone_by_id)
#  index_messages_on_id                          (id) UNIQUE
#  index_messages_on_message_type                (message_type)
#
# Foreign Keys
#
#  call_id                     (call_id => calls.id)
#  deleted_for_everyone_by_id  (deleted_for_everyone_by_id => users.id)
#
class Message < ApplicationRecord
  belongs_to :chatroom
  belongs_to :user
  belongs_to :call, optional: true
  has_many_attached :attachments

  acts_as_paranoid

  encrypts :body

  enum :message_type, { text: "text", voice: "voice", image: "image", file: "file", system: "system", call: "call" }

  scope :ordered, -> { order(created_at: :asc) }

  validate :body_or_attachments_present
  validate :voice_note_size_limit

  def image_attachments
    attachments.select { |a| a.content_type.start_with?("image/") }
  end

  def audio_attachments
    attachments.select { |a| a.content_type.start_with?("audio/") }
  end

  def file_attachments
    attachments.reject { |a| a.content_type.start_with?("image/", "audio/") }
  end

  private

  def body_or_attachments_present
    # Call-summary messages carry their info via the `call` association and
    # `duration_in_seconds`, not `body` or attachments, so they're exempt
    # from the usual "must have text or a file" rule.
    return if message_type == "call" && call.present?

    errors.add(:base, "Message must have text or an attachment") if body.blank? && attachments.blank?
  end

  def voice_note_size_limit
    audio_attachments.each do |a|
      errors.add(:attachments, "voice note is too large (max 10MB)") if a.byte_size > 10.megabytes
    end
  end
end
