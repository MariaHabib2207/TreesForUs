# == Schema Information
#
# Table name: visibility_permissions
#
#  id           :integer          not null, primary key
#  setting_type :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#  viewer_id    :integer          not null
#
# Indexes
#
#  index_visibility_permissions_on_user_id    (user_id)
#  index_visibility_permissions_on_viewer_id  (viewer_id)
#  index_visibility_permissions_uniqueness    (user_id,viewer_id,setting_type) UNIQUE
#
# Foreign Keys
#
#  user_id    (user_id => users.id)
#  viewer_id  (viewer_id => users.id)
#
class VisibilityPermission < ApplicationRecord
  belongs_to :user
  belongs_to :viewer, class_name: "User"

  validates :setting_type, inclusion: { in: %w[last_seen online avatar] }
end
