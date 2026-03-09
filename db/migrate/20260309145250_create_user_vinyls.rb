class CreateUserVinyls < ActiveRecord::Migration[8.1]
  def change
    create_table :user_vinyls do |t|
      t.references :user, foreign_key: true, null: false
      t.references :vinyl, foreign_key: true, null: false
      t.timestamps
    end
  end
end
