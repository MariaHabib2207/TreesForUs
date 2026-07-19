class VisibilityPermission < ApplicationRecord
  belongs_to :user
  belongs_to :viewer, class_name: "User"

  validates :setting_type, inclusion: { in: %w[last_seen online avatar] }
end