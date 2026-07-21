class AllowUsersWithoutLogin < ActiveRecord::Migration[8.0]
  def change
    # Allow users without email
    change_column_null :users, :email, true
    change_column_default :users, :email, from: "", to: nil

    # Allow users without password
    change_column_null :users, :encrypted_password, true
    change_column_default :users, :encrypted_password, from: "", to: nil

    # Optional login flag
    add_column :users, :login_enabled, :boolean, default: false, null: false
  end
end
