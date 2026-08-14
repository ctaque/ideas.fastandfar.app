class AddPostToComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :post, null: false, foreign_key: true
  end
end
