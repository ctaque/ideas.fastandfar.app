class MigrateCommentsCommentToActionText < ActiveRecord::Migration[8.1]
  class MigrationComment < ApplicationRecord
    self.table_name = "comments"
    self.inheritance_column = :_type_disabled
  end

  def up
    MigrationComment.reset_column_information

    MigrationComment.find_each do |comment|
      next if comment.comment.blank?
      ActionText::RichText.create!(record_type: "Comment", record_id: comment.id, name: "comment", body: comment.comment)
    end

    remove_column :comments, :comment
  end

  def down
    add_column :comments, :comment, :text

    ActionText::RichText.where(record_type: "Comment", name: "comment").find_each do |rich_text|
      MigrationComment.where(id: rich_text.record_id).update_all(comment: rich_text.body&.to_plain_text)
    end
  end
end
