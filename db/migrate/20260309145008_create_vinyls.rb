class CreateVinyls < ActiveRecord::Migration[8.1]
  def change
    create_table :vinyls do |t|
      t.string :title
      t.string :artist
      t.integer :year
      t.string :format
      t.json :tracks
      t.string :genre
      t.string :artwork_url

      t.timestamps
    end
  end
end
