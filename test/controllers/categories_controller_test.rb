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
end
