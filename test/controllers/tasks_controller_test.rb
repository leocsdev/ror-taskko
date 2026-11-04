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
end
