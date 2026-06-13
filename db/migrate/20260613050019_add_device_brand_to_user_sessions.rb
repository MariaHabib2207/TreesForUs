class AddDeviceBrandToUserSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :user_sessions, :device_brand, :string
  end
end
