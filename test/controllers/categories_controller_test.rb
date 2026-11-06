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

  # 3. GET /categories/:id/edit
  test "should get edit" do
    get edit_category_url(@category)

    assert_response :success
    assert_select "turbo-frame##{dom_id(@category)}"
  end

  # 4. POST /categories (HTML & Turbo Stream)
  test "should create category with valid attributes via HTML" do
    assert_difference("Category.count", 1) do
      post categories_url, params: {
        category: { name: "Finance" }
      }
    end

    assert_redirected_to categories_url
    assert_response :see_other
  end

  test "should not create category with invalid attributes via HTML" do
    assert_no_difference("Category.count") do
      post categories_url, params: {
        category: { name: "" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should create category via Turbo Stream" do
    assert_difference("Category.count", 1) do
      post categories_url, params: {
        category: { name: "Learning" }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "Learning"
  end

  test "should not create duplicate category via Turbo Stream" do
    assert_no_difference("Category.count") do
      post categories_url, params: {
        category: { name: "work" } # case-insensitive duplicate
      }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "has already been taken"
  end

  # 5. PATCH /categories/:id (HTML & Turbo Stream)
  test "should update category with valid attributes via HTML" do
    patch category_url(@category), params: {
      category: { name: "Career" }
    }

    assert_redirected_to categories_url
    assert_response :see_other
    assert_equal "Career", @category.reload.name
  end

  test "should not update category with invalid attributes" do
    patch category_url(@category), params: {
      category: { name: "" }
    }

    assert_response :unprocessable_entity
    assert_equal "Work", @category.reload.name
  end

  test "should update category via Turbo Stream" do
    patch category_url(@category), params: {
      category: { name: "Career" }
    }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal "Career", @category.reload.name
  end

  # 6. DELETE /categories/:id (destroy & task nullification)
  test "should destroy category and nullify associated tasks via HTML" do
    task = Task.create!(name: "Assigned Task", category: @category)
    assert_difference("Category.count", -1) do
      delete category_url(@category)
    end

    assert_redirected_to categories_url
    assert_response :see_other
    assert_nil task.reload.category_id
  end

  test "should destroy category via Turbo Stream" do
    assert_difference("Category.count", -1) do
      delete category_url(@category), as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end
end
