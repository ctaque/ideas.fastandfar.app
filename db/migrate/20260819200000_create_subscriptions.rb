class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: false
      t.string :user_email, null: false

      t.timestamps
    end

    add_index :subscriptions, [ :post_id, :user_id ], unique: true
  end
end
