class AddUserNicknameToPostsAndComments < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :user_nickname, :string
    add_column :comments, :user_nickname, :string
  end
end
