require "test_helper"

# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_categories_on_lower_name  (lower((name)::text)) UNIQUE
#
class CategoryTest < ActiveSupport::TestCase
  test "should not save category without name" do
    category = Category.new(name: nil)
    
    assert_not category.save
    assert_includes category.errors[:name], "can't be blank"
  end

  test "should not allow category names with different casing" do
    Category.create!(name: "Work")

    duplicate_category = Category.new(name: "work")

    assert_not duplicate_category.save
    assert_includes duplicate_category.errors[:name], "has already been taken"
  end

  test "should nullify associated task category when category is deleted" do
    category = Category.create!(name: "Work")

    task = Task.create!(
      title: "Sample Task",
      category: category,
      ai_suggested_category: category
    )

    # Delete the categor
    category.destroy

    # Reload the task to reflect changes in the database
    task.reload

    assert_nil task.category
    assert_nil task.ai_suggested_category
  end
end
