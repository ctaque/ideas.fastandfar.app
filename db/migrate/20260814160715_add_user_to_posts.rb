class AddUserToPosts < ActiveRecord::Migration[8.1]
  def up
    add_reference :posts, :user, foreign_key: true

    default_user_id = User.order(:id).first&.id
    execute "UPDATE posts SET user_id = #{default_user_id} WHERE user_id IS NULL" if default_user_id

    change_column_null :posts, :user_id, false
  end

  def down
    remove_reference :posts, :user, foreign_key: true
  end
end
