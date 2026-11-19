# Profile pictures are owned by fastandfarapp and change over time, so they're read
# from the signed-in user's `avatar_url` claim at render time instead of being
# snapshotted onto every record.
class RemoveUserAvatarUrlFromPostsCommentsAndSubscriptions < ActiveRecord::Migration[8.1]
  def change
    remove_column :posts, :user_avatar_url, :string
    remove_column :comments, :user_avatar_url, :string
    remove_column :subscriptions, :user_avatar_url, :string
  end
end
