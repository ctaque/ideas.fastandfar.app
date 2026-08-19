class AddUserNicknameAndAvatarUrlToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :subscriptions, :user_nickname, :string
    add_column :subscriptions, :user_avatar_url, :string
  end
end
