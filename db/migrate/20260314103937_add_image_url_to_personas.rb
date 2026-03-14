class AddImageUrlToPersonas < ActiveRecord::Migration[8.1]
  def change
    add_column :personas, :image_url, :string
  end
end
