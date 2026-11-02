class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false

      t.timestamps
    end

    # Add a unique index to the name column to enforce uniqueness at the database level
    add_index :categories, :name, unique: true
  end
end
