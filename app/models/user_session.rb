# == Schema Information
#
# Table name: user_sessions
#
#  id              :integer          not null, primary key
#  browser         :string
#  browser_version :string
#  city            :string
#  continent       :string
#  country         :string
#  device_brand    :string
#  device_name     :string
#  device_type     :string
#  ip_address      :string
#  last_active_at  :datetime
#  latitude        :float
#  longitude       :float
#  os              :string
#  os_version      :string
#  region          :string
#  user_agent      :string
#  zip             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer          not null
#
# Indexes
#
#  index_user_sessions_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class UserSession < ApplicationRecord
  belongs_to :user

  def self.ransackable_attributes(auth_object = nil)
    %w[browser browser_version city country created_at device_name
       device_type id ip_address last_active_at latitude longitude
       os os_version region updated_at user_agent user_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end
end
