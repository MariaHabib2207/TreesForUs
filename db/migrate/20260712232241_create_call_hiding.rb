class CreateCallHiding < ActiveRecord::Migration[8.0]
  def change
    create_table :call_hidings do |t|
      t.references :call, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :call_hidings, [:call_id, :user_id], unique: true
  end
end
