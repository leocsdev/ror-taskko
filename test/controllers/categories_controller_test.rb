require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Work")
  end

  # 1. GET /categories
  test "should get index" do
    get categories_url

    assert_response :success
    assert_select "turbo-frame#modal"
    assert_includes response.body, @category.name
  end

  # 2. GET /categories/:id (used by Cancel button in inline edit)
  test "should get show" do
    get category_url(@category)

    assert_response :success
    assert_includes response.body, @category.name
  end
end
