class RemovingConfirmableFromAdminUsers < ActiveRecord::Migration[8.0]
  
    remove_column :admin_users, :confirmed_at
    remove_column :admin_users, :confirmation_sent_at
    remove_column :admin_users, :unconfirmed_email
  end

  def down

    add_column :admin_users, :confirmed_at,         :datetime
    add_column :admin_users, :confirmation_sent_at, :datetime
    add_column :admin_users, :unconfirmed_email,    :string


  end
end
