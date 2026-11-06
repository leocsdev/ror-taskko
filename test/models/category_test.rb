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
      name: "Sample Task",
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

  test "with_tasks_count scope computes tasks count accurately" do
    work = Category.create!(name: "Work")
    personal = Category.create!(name: "Personal")
    # Category with no tasks
    Category.create!(name: "Chores")

    Task.create!(name: "Task 1", category: work)
    Task.create!(name: "Task 2", category: work)
    Task.create!(name: "Task 3", category: personal)

    categories = Category.with_tasks_count.index_by(&:name)

    assert_equal 2, categories["Work"].tasks_count
    assert_equal 1, categories["Personal"].tasks_count
    assert_equal 0, categories["Chores"].tasks_count
  end

  test "tasks_count falls back to database count when un-aggregated" do
    category = Category.create!(name: "Health")
    Task.create!(name: "Run 5k", category: category)

    # Calling on a standard find (without with_tasks_count) uses fallback
    found_category = Category.find(category.id)
    assert_equal 1, found_category.tasks_count

    # Brand new unsaved record
    new_category = Category.new(name: "Fitness")
    assert_equal 0, new_category.tasks_count
  end
end
