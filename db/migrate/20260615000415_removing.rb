class Removing < ActiveRecord::Migration[8.0]
  def up

    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email
  end

  def down

    add_column :users, :confirmed_at,         :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email,    :string

  end
end
