class AddImageCreditToPersona < ActiveRecord::Migration[8.1]
  def change
    add_column :personas, :image_credit, :string
  end
end
