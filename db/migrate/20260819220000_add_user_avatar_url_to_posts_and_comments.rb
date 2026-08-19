class AddUserAvatarUrlToPostsAndComments < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :user_avatar_url, :string
    add_column :comments, :user_avatar_url, :string
  end
end
