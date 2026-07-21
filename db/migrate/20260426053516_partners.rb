class Partners < ActiveRecord::Migration[8.0]
  def change
    create_table :user_partners do |t|
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.references :partner, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :user_partners, [ :user_id, :partner_id ], unique: true
  end
end
