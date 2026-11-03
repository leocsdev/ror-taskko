class MakeCategoryNameUniquenessCaseInsensitive < ActiveRecord::Migration[8.1]
  def change
    remove_index :categories, :name
    add_index :categories,
              "LOWER(name)",
              unique: true,
              name: "index_categories_on_lower_name"
  end
end
