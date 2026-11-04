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

  test "should create task via Turbo Stream" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: {
        task: {
          name: "Buy groceries",
          description: "Milk, eggs, bread",
          category_id: category.id,
          priority: "high"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not create task via turbo stream with invalid attributes" do
    assert_no_difference("Task.count") do
      post tasks_url, params: {
        task: {
          name: nil,
          description: "Milk, eggs, bread",
          category_id: category.id,
          priority: "high"
        }
      }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should update task with valid attributes" do
    patch task_url(task), params: {
      task: {
        name: "Updated Task Title",
        priority: "urgent"
      }
    }

    task.reload
    assert_equal "Updated Task Title", task.name
    assert_equal "urgent", task.priority
    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should not update task with invalid attributes" do
    patch task_url(task), params: {
      task: {
        name: ""
      }
    }

    task.reload

    assert_equal "Submit report", task.name
    assert_response :unprocessable_entity
  end

  test "should update task via turbo stream" do
    patch task_url(task), params: {
      task: {
        name: "Updated via Turbo",
        priority: "urgent"
      }
    }, as: :turbo_stream

    task.reload

    assert_equal "Updated via Turbo", task.name
    assert_equal "urgent", task.priority
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not update task via turbo stream with invalid attributes" do
    patch task_url(task), params: {
      task: {
        name: ""
      }
    }, as: :turbo_stream

    task.reload

    assert_equal "Submit report", task.name
    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should mark an active task as completed" do
    assert_nil task.completed_at
    patch toggle_completion_task_url(task)

    task.reload

    assert_not_nil task.completed_at
    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should reopen a completed task" do
    task.update!(completed_at: Time.current)
    patch toggle_completion_task_url(task)

    task.reload

    assert_nil task.completed_at
    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should toggle completion via turbo stream" do
    patch toggle_completion_task_url(task), as: :turbo_stream

    task.reload
    assert_not_nil task.completed_at
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete task_url(task)
    end

    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should destroy task via turbo stream" do
    assert_difference("Task.count", -1) do
      delete task_url(task), as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end
end
