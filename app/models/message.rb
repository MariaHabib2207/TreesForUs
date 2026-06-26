class Message < ApplicationRecord
  belongs_to :chatroom
  belongs_to :user
  has_many_attached :attachments

  encrypts :body

  scope :ordered, -> { order(created_at: :asc) }

  def image_attachments
    attachments.select { |a| a.content_type.start_with?("image/") }
  end

  def audio_attachments
    attachments.select { |a| a.content_type.start_with?("audio/") }
  end

  def file_attachments
    attachments.reject { |a| a.content_type.start_with?("image/", "audio/") }
  end
end