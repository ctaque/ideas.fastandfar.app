class MigratePostsContentToActionText < ActiveRecord::Migration[8.1]
  class MigrationPost < ApplicationRecord
    self.table_name = "posts"
    self.inheritance_column = :_type_disabled
  end

  def up
    MigrationPost.reset_column_information

    MigrationPost.find_each do |post|
      next if post.content.blank?
      ActionText::RichText.create!(record_type: "Post", record_id: post.id, name: "content", body: post.content)
    end

    remove_column :posts, :content
  end

  def down
    add_column :posts, :content, :text

    ActionText::RichText.where(record_type: "Post", name: "content").find_each do |rich_text|
      MigrationPost.where(id: rich_text.record_id).update_all(content: rich_text.body&.to_plain_text)
    end
  end
end
