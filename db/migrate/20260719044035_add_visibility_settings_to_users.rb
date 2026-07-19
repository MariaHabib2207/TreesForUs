
class AddVisibilitySettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_seen_visibility, :string, default: "everyone", null: false
    add_column :users, :online_visibility, :string, default: "everyone", null: false
    add_column :users, :avatar_visibility, :string, default: "everyone", null: false
  end
end