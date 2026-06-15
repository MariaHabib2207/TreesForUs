class RemovingConfirmableFromAdminUsers < ActiveRecord::Migration[8.0]
  def up
    remove_column :admin_users, :confirmation_token
    remove_column :admin_users, :confirmed_at
    remove_column :admin_users, :confirmation_sent_at
    remove_column :admin_users, :unconfirmed_email
  end

  def down
    add_column :admin_users, :confirmation_token,   :string
    add_column :admin_users, :confirmed_at,         :datetime
    add_column :admin_users, :confirmation_sent_at, :datetime
    add_column :admin_users, :unconfirmed_email,    :string

    add_index :admin_users, :confirmation_token, unique: true
  end
end
