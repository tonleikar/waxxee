class AddAvatarSourceTypeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_source_type, :string, default: "generated", null: false
  end
end
