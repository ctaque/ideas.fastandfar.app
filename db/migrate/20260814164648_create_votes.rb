class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :value, null: false

      t.timestamps
    end

    add_index :votes, [ :post_id, :user_id ], unique: true
  end
end
