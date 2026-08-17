class AddTypeToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :type, :string, default: "idea", null: false
  end
end
