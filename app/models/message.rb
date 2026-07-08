class Message < ApplicationRecord
  belongs_to :chatroom
  belongs_to :user
  has_many_attached :attachments

  encrypts :body

  enum :message_type, { text: "text", voice: "voice", image: "image", file: "file", system: "system"  }

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
    errors.add(:base, "Message must have text or an attachment") if body.blank? && attachments.blank?
  end

  def voice_note_size_limit
    audio_attachments.each do |a|
      errors.add(:attachments, "voice note is too large (max 10MB)") if a.byte_size > 10.megabytes
    end
  end
end