# app/models/life_activity.rb
class LifeActivity < ApplicationRecord
  belongs_to :user
  has_many_attached :photos

  CATEGORIES = %w[travel kids marriage education career milestone other].freeze

  VISIBILITY_OPTIONS = {
    "Only Me (Private)"  => "private",
    "Friends Only"       => "friends",
    "Family Only"        => "family",
    "Friends & Family"   => "friends_and_family"
  }.freeze

  validates :title,      presence: true, length: { maximum: 120 }
  validates :category,   presence: true, inclusion: { in: CATEGORIES }
  validates :visibility, presence: true, inclusion: { in: VISIBILITY_OPTIONS.values }
  validate  :validate_photos

  scope :visible_to, ->(viewer, owner) {
    return all if viewer == owner
    if viewer.friends_with?(owner) && viewer.family_with?(owner)
      where(visibility: %w[friends family friends_and_family])
    elsif viewer.friends_with?(owner)
      where(visibility: %w[friends friends_and_family])
    elsif viewer.family_with?(owner)
      where(visibility: %w[family friends_and_family])
    else
      none
    end
  }

  scope :chronological, -> { order(occurred_on: :desc, created_at: :desc) }

  def category_emoji
    {
      "travel"    => "✈️",
      "kids"      => "👶",
      "marriage"  => "💍",
      "education" => "🎓",
      "career"    => "💼",
      "milestone" => "🏆",
      "other"     => "⭐"
    }[category] || "⭐"
  end

  private

  def validate_photos
    return unless photos.attached?

    if photos.count > 10
      errors.add(:photos, "maximum 10 photos allowed")
      return
    end

    allowed_types = %w[image/png image/jpg image/jpeg image/webp image/gif]

    photos.each do |photo|
      unless allowed_types.include?(photo.content_type)
        errors.add(:photos, "must be PNG, JPG, WEBP or GIF")
      end

      if photo.byte_size > 10.megabytes
        errors.add(:photos, "must be under 10MB each")
      end
    end
  end
end