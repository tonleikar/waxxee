class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :favorite_genre, :string
    add_column :users, :avatar_url, :string
    add_reference :users, :favorite_vinyl, foreign_key: { to_table: :vinyls }
  end
end
