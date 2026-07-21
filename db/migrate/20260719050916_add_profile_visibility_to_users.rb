
class AddProfileVisibilityToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :profile_visibility, :string, default: "public", null: false
  end
end