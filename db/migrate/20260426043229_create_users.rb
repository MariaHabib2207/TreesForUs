class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.timestamps
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.integer :identification_type, null: false, default: 0
      t.string :identification_number, null: false
      t.integer :status, null: false, default: 0
      t.integer :role, null: false, default: 0
      t.integer :created_by
      t.integer :updated_by
    end

    add_index :users, [ :identification_type, :identification_number ], unique: true, name: "index_users_on_id_type_and_number"
  end
end
