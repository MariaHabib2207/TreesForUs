class ParentRelationshipToUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :user_parent_child_relationships do |t|
      t.integer :parent_id
      t.integer :child_id
      t.timestamps
    end

    add_index :user_parent_child_relationships,
              [ :parent_id, :child_id ],
              unique: true
  end
end
