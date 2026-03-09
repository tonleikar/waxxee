class CreatePersonas < ActiveRecord::Migration[8.1]
  def change
    create_table :personas do |t|
      t.string :title
      t.string :url

      t.timestamps
    end
  end
end
