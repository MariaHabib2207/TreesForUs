# == Schema Information
#
# Table name: messages
#
#  id                         :integer          not null, primary key
#  body                       :text
#  deleted_at                 :datetime
#  deleted_for_everyone_at    :datetime
#  delivered_at               :datetime
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
#  index_messages_on_delivered_at                (delivered_at)
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
  belongs_to :deleted_for_everyone_by, class_name: "User", optional: true
  has_many :message_hidings, dependent: :destroy
  has_many_attached :attachments

  acts_as_paranoid

  encrypts :body

  enum :message_type, { text: "text", voice: "voice", image: "image", file: "file", system: "system", call: "call" }

  scope :ordered, -> { order(created_at: :asc) }
scope :visible_for, ->(user) {
  where.not(id: MessageHiding.where(user: user).select(:message_id))
       .where(
         "messages.call_id IS NULL OR messages.call_id NOT IN (SELECT call_id FROM call_hidings WHERE user_id = ?)",
         user.id
       )
}

  validate :body_or_attachments_present
  validate :voice_note_size_limit

  def deleted_for_everyone?
    deleted_for_everyone_at.present?
  end

  def hidden_for?(user)
    message_hidings.exists?(user_id: user.id)
  end

  # "Delete for me" — hides this message for this user only.
  def hide_for(user)
    message_hidings.find_or_create_by(user: user)
  end

  # "Delete for everyone" — message stays queryable but renders as a
  # tombstone for all participants. Not a paranoid destroy: ordering,
  # counts, and read-receipts should keep working normally.
  def delete_for_everyone!(deleter)
    update!(deleted_for_everyone_at: Time.current, deleted_for_everyone_by_id: deleter.id)
  end

  def image_attachments
    attachments.select { |a| a.content_type.start_with?("image/") }
  end

  def audio_attachments
    attachments.select { |a| a.content_type.start_with?("audio/") }
  end

  def file_attachments
    attachments.reject { |a| a.content_type.start_with?("image/", "audio/") }
  end
  def delivered?
    delivered_at.present?
  end

  def read?
    read_at.present?
  end

  private

  def body_or_attachments_present
    return if message_type == "call" && call.present?
    return if deleted_for_everyone?

    errors.add(:base, "Message must have text or an attachment") if body.blank? && attachments.blank?
  end

  def voice_note_size_limit
    audio_attachments.each do |a|
      errors.add(:attachments, "voice note is too large (max 10MB)") if a.byte_size > 10.megabytes
    end
  end
end
