class AddGeneratedFieldsToPersonas < ActiveRecord::Migration[8.1]
  def change
    add_reference :personas, :user, foreign_key: true
    add_column :personas, :prompt, :text
    add_column :personas, :summary, :text
    add_column :personas, :min_year, :integer, default: 1900, null: false
    add_column :personas, :max_year, :integer, default: 2026, null: false
    add_column :personas, :genres, :json, default: [], null: false
    add_column :personas, :keywords, :json, default: [], null: false
    add_column :personas, :llm_model, :string
    add_column :personas, :primary_profile, :boolean, default: false, null: false
  end
end
