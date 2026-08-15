class RemoveLocalUsers < ActiveRecord::Migration[8.1]
  # Identity moves entirely to the Rust service: Rails no longer owns credentials or
  # server-side login sessions, only the email of whoever authored a post/comment/vote
  # (snapshotted at write time, since there is no local users table left to join against).
  def up
    add_column :posts, :user_email, :string
    add_column :comments, :user_email, :string
    add_column :votes, :user_email, :string

    execute "UPDATE posts SET user_email = (SELECT email_address FROM users WHERE users.id = posts.user_id)"
    execute "UPDATE comments SET user_email = (SELECT email_address FROM users WHERE users.id = comments.user_id)"
    execute "UPDATE votes SET user_email = (SELECT email_address FROM users WHERE users.id = votes.user_id)"

    change_column_null :posts, :user_email, false
    change_column_null :comments, :user_email, false
    change_column_null :votes, :user_email, false

    remove_foreign_key :comments, :users
    remove_foreign_key :posts, :users
    remove_foreign_key :sessions, :users
    remove_foreign_key :votes, :users

    drop_table :sessions
    drop_table :users
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
