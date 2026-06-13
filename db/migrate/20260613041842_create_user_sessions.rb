class CreateUserSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :city
      t.string :country
      t.string :region
      t.string :browser
      t.string :browser_version
      t.string :os
      t.string :os_version
      t.string :device_type
      t.string :device_name
      t.datetime :last_active_at
      t.string :user_agent
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
