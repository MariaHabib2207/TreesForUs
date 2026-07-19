
class CreateVisibilityPermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :visibility_permissions do |t|
      t.references :user, null: false, foreign_key: true       # the owner of the setting
      t.references :viewer, null: false, foreign_key: { to_table: :users } # who is allowed to see it
      t.string :setting_type, null: false # "last_seen" | "online" | "avatar"
      t.timestamps
    end
    add_index :visibility_permissions, [:user_id, :viewer_id, :setting_type], unique: true, name: "index_visibility_permissions_uniqueness"
  end
end