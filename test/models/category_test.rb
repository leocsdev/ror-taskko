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
end
