class AddStaffPickToPersonas < ActiveRecord::Migration[8.1]
  def change
    add_column :personas, :staff_pick, :boolean, default: false, null: false
  end
end
