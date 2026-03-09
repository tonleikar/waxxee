class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.string :name
      t.references :user, foreign_key: true, null: false

      t.timestamps
    end
  end
end
