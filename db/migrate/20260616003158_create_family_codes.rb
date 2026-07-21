class CreateFamilyCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :family_codes do |t|
      t.references :family,          null: false, foreign_key: true
      t.references :created_by,      null: false, foreign_key: { to_table: :users }
      t.string     :code,            null: false
      t.string     :email,           null: false          # who it was sent to
      t.integer    :membership_type, null: false          # pre-set by manager
      t.datetime   :expires_at,      null: false
      t.datetime   :used_at                               # nil = unused
      t.references :used_by,         foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :family_codes, :code,  unique: true
    add_index :family_codes, :email
  end
end
