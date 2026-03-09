class CreateFolderVinyls < ActiveRecord::Migration[8.1]
  def change
    create_table :folder_vinyls do |t|
      t.timestamps
      t.references :folder, foreign_key: true, null: false
      t.references :user_vinyl, foreign_key: true, null: false
    end
  end
end
