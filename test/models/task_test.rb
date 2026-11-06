require "test_helper"

# == Schema Information
#
# Table name: tasks
#
#  id                       :bigint           not null, primary key
#  ai_analyzed_at           :datetime
#  ai_reason                :text
#  ai_status                :string           default("not_requested"), not null
#  ai_suggested_priority    :string
#  completed_at             :datetime
#  description              :text
#  due_at                   :datetime
#  name                     :string           not null
#  priority                 :string           default("medium"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  ai_suggested_category_id :bigint
#  category_id              :bigint
#
# Indexes
#
#  index_tasks_on_ai_suggested_category_id  (ai_suggested_category_id)
#  index_tasks_on_category_id               (category_id)
#
# Foreign Keys
#
#  fk_rails_...  (ai_suggested_category_id => categories.id)
#  fk_rails_...  (category_id => categories.id)
#
class TaskTest < ActiveSupport::TestCase
  test "should accept valid priorities" do
    Task::PRIORITIES.each do |priority|
      task = Task.new(name: "Sample Task", priority: priority)
      assert task.valid?, "Expected task with priority #{priority} to be valid"
    end
  end

  test "should reject invalid priorities" do
    task = Task.new(name: "Sample Task", priority: "invalid_priority")
    assert_not task.valid?
    assert_includes task.errors[:priority], "is not included in the list"
  end

  test "should accept valid AI statuses" do
    Task::AI_STATUSES.each do |status|
      task = Task.new(name: "Sample Task", ai_status: status)
      assert task.valid?, "Expected task with AI status #{status} to be valid"
    end
  end

  test "should reject invalid AI statuses" do
    task = Task.new(name: "Sample Task", ai_status: "invalid_status")
    assert_not task.valid?
    assert_includes task.errors[:ai_status], "is not included in the list"
  end

  test "should accept valid AI suggested priorities" do
    Task::PRIORITIES.each do |priority|
      task = Task.new(name: "Sample Task", ai_suggested_priority: priority)
      assert task.valid?, "Expected task with AI suggested priority #{priority} to be valid"
    end
  end

  test "should reject invalid AI suggested priorities" do
    task = Task.new(name: "Sample Task", ai_suggested_priority: "invalid_priority")
    assert_not task.valid?
    assert_includes task.errors[:ai_suggested_priority], "is not included in the list"
  end

  test "should accept nil for AI suggested priority" do
    task = Task.new(name: "Sample Task", ai_suggested_priority: nil)
    assert task.valid?
  end

  test "should be valid without a category" do
    task = Task.new(name: "Sample Task", category: nil)

    assert task.valid?
  end

  test "should be valid without an AI suggested category" do
    task = Task.new(name: "Sample Task", ai_suggested_category: nil)

    assert task.valid?
  end

  test "scope ordered returns tasks with newest created first" do
    task_old = Task.create!(name: "Old task", priority: "medium", created_at: 2.days.ago)
    task_new = Task.create!(name: "New task", priority: "high", created_at: 1.day.ago)

    ordered_tasks = Task.where(id: [ task_old.id, task_new.id ]).ordered
    assert_equal [ task_new, task_old ], ordered_tasks.to_a
  end

  test "scopes active and completed filter by completion state" do
    active_task = Task.create!(name: "Active task", priority: "medium", completed_at: nil)
    completed_task = Task.create!(name: "Completed task", priority: "low", completed_at: Time.current)

    assert_includes Task.active, active_task
    assert_not_includes Task.active, completed_task

    assert_includes Task.completed, completed_task
    assert_not_includes Task.completed, active_task
  end

  test "completed? returns true only when completed_at is present" do
    task = Task.new(name: "Test", priority: "medium")
    assert_not task.completed?

    task.completed_at = Time.current
    assert task.completed?
  end

  test "due_today? returns true when due date is today" do
    task = Task.new(name: "Test", priority: "medium", due_at: Time.zone.now.beginning_of_day + 14.hours)
    assert task.due_today?

    task.due_at = 1.day.from_now
    assert_not task.due_today?
  end

  test "overdue? returns true when due date is in the past and task is active" do
    task = Task.new(name: "Test", priority: "medium", due_at: 2.days.ago)
    assert task.overdue?

    # When marked completed, it is no longer considered overdue
    task.completed_at = Time.current
    assert_not task.overdue?
  end
end
