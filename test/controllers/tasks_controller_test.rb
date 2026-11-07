require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Work")
    @task = Task.create!(name: "Submit report", category: @category, priority: "medium")
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
    get edit_task_url(@task)
    assert_response :success
  end

  test "should create task with valid attributes" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: {
        task: {
          name: "Buy groceries",
          description: "Milk, eggs, bread",
          category_id: @category.id,
          priority: "high"
        }
      }
    end

    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should not create task with invalid attributes" do
    assert_no_difference("Task.count") do
      post tasks_url,
           params: {
             task: {
               name: nil,
               description: "Milk, eggs, bread",
               category_id: @category.id,
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
          category_id: @category.id,
          priority: "high"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select %(turbo-stream[action="update"][target="header_active_tasks_count"]), text: "2"
    assert_select %(turbo-stream[action="update"][target="active_tasks_count"]), text: "2"
    assert_select %(turbo-stream[action="update"][target="total_tasks_count"]), text: "2"
  end

  test "should not create task via turbo stream with invalid attributes" do
    assert_no_difference("Task.count") do
      post tasks_url, params: {
        task: {
          name: nil,
          description: "Milk, eggs, bread",
          category_id: @category.id,
          priority: "high"
        }
      }, as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should update task with valid attributes" do
    patch task_url(@task), params: {
      task: {
        name: "Updated Task Title",
        priority: "urgent"
      }
    }

    @task.reload
    assert_equal "Updated Task Title", @task.name
    assert_equal "urgent", @task.priority
    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should not update task with invalid attributes" do
    patch task_url(@task), params: {
      task: {
        name: "",
        priority: "urgent"
      }
    }

    @task.reload

    assert_equal "Submit report", @task.name
    assert_equal "medium", @task.priority
    assert_response :unprocessable_entity
  end

  test "should update task via turbo stream" do
    patch task_url(@task), params: {
      task: {
        name: "Updated via Turbo",
        priority: "urgent"
      }
    }, as: :turbo_stream

    @task.reload

    assert_equal "Updated via Turbo", @task.name
    assert_equal "urgent", @task.priority
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not update task via turbo stream with invalid attributes" do
    patch task_url(@task), params: {
      task: {
        name: "",
        priority: "urgent"
      }
    }, as: :turbo_stream

    @task.reload

    assert_equal "Submit report", @task.name
    assert_equal "medium", @task.priority
    assert_response :unprocessable_entity
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should mark an active task as completed" do
    assert_nil @task.completed_at
    patch toggle_completion_task_url(@task)

    @task.reload

    assert_not_nil @task.completed_at
    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should reopen a completed task" do
    @task.update!(completed_at: Time.current)
    patch toggle_completion_task_url(@task)

    @task.reload

    assert_nil @task.completed_at
    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should toggle completion via turbo stream" do
    patch toggle_completion_task_url(@task), as: :turbo_stream

    @task.reload
    assert_not_nil @task.completed_at
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select %(turbo-stream[action="update"][target="header_active_tasks_count"]), text: "0"
    assert_select %(turbo-stream[action="update"][target="active_tasks_count"]), text: "0"
    assert_select %(turbo-stream[action="update"][target="completed_tasks_count"]), text: "1"
  end

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end

    assert_redirected_to root_url
    assert_response :see_other
  end

  test "should destroy task via turbo stream" do
    assert_difference("Task.count", -1) do
      delete task_url(@task), as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select %(turbo-stream[action="update"][target="header_active_tasks_count"]), text: "0"
    assert_select %(turbo-stream[action="update"][target="active_tasks_count"]), text: "0"
    assert_select %(turbo-stream[action="update"][target="total_tasks_count"]), text: "0"
  end

  test "should filter tasks by active status" do
    Task.create!(name: "Active task", priority: "medium", completed_at: nil)
    Task.create!(name: "Completed task", priority: "medium", completed_at: Time.current)

    get root_url(status: "active")
    assert_response :success
    assert_includes response.body, "Active task"
    assert_not_includes response.body, "Completed task"
  end

  test "should filter tasks by completed status" do
    Task.create!(name: "Active task", priority: "medium", completed_at: nil)
    Task.create!(name: "Completed task", priority: "medium", completed_at: Time.current)

    get root_url(status: "completed")
    assert_response :success
    assert_includes response.body, "Completed task"
    assert_not_includes response.body, "Active task"
  end

  test "should filter tasks by category" do
    personal_category = Category.create!(name: "Personal")
    Task.create!(name: "Buy groceries", category: personal_category, priority: "low")

    get root_url(category_id: personal_category.id)
    assert_response :success
    assert_includes response.body, "Buy groceries"
    assert_not_includes response.body, "Submit report"
  end

  test "should filter tasks by priority" do
    Task.create!(name: "Server is down", priority: "urgent")

    get root_url(priority: "urgent")
    assert_response :success
    assert_includes response.body, "Server is down"
    assert_not_includes response.body, "Submit report"
  end

  test "should combine filters" do
    Task.create!(name: "Fix production bug", category: @category, priority: "urgent")
    Task.create!(name: "Old urgent bug", category: @category, priority: "urgent", completed_at: Time.current)

    get root_url(status: "active", category_id: @category.id, priority: "urgent")
    assert_response :success
    assert_includes response.body, "Fix production bug"
    assert_not_includes response.body, "Old urgent bug"
    assert_not_includes response.body, "Submit report"
  end

  test "should render empty state when no tasks match filter" do
    get root_url(status: "completed")
    assert_response :success
    assert_includes response.body, "No tasks found"
    assert_includes response.body, "You have not completed any tasks in this view yet."
  end
end
