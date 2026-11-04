require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  attr_accessor :category, :task

  setup do
    @category = Category.create!(name: "Work")
    @task = Task.create!(name: "Submit report", category:, priority: "medium")
  end

  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should get new task form" do
    get new_task_url
    assert_response :success
  end

  test "should get edit" do
    get edit_task_url(task)
    assert_response :success
  end

  test "should create task with valid attributes" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: {
        task: {
          name: "Buy groceries",
          description: "Milk, eggs, bread",
          category_id: category.id,
          priority: "high"
        }
      }
    end

    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should not create task with invalid attributes" do
    assert_difference("Task.count", 0) do
      post tasks_url,
           params: {
             task: {
               name: nil,
               description: "Milk, eggs, bread",
               category_id: category.id,
               priority: "high"
             }
           }
    end

    assert_response :unprocessable_entity
  end
end
