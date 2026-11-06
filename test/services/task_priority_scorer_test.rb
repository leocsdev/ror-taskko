require "test_helper"

class TaskPriorityScorerTest < ActiveSupport::TestCase
  setup do
    @today = Date.new(2026, 11, 7)
  end

  test "excludes completed tasks from ranking" do
    active_task = Task.new(name: "Active task", priority: "medium", created_at: 1.day.ago)
    completed_task = Task.new(name: "Done task", priority: "urgent", completed_at: Time.current, created_at: 1.day.ago)

    ranked = TaskPriorityScorer.rank([active_task, completed_task], reference_date: @today)

    assert_includes ranked, active_task
    assert_not_includes ranked, completed_task
  end

  test "overdue tasks strictly dominate over due today and upcoming tasks" do
    overdue_low = Task.new(name: "Overdue Low", priority: "low", due_at: @today - 2.days, created_at: 3.days.ago)
    overdue_urgent = Task.new(name: "Overdue Urgent", priority: "urgent", due_at: @today - 1.day, created_at: 3.days.ago)
    due_today_urgent = Task.new(name: "Due Today Urgent", priority: "urgent", due_at: @today.beginning_of_day, created_at: 2.days.ago)
    future_urgent = Task.new(name: "Future Urgent", priority: "urgent", due_at: @today + 2.days, created_at: 1.day.ago)

    ranked = TaskPriorityScorer.rank([future_urgent, overdue_low, due_today_urgent, overdue_urgent], reference_date: @today)

    assert_equal [overdue_urgent, overdue_low, due_today_urgent, future_urgent], ranked
  end

  test "internal ordering within overdue tasks respects priority" do
    overdue_urgent = Task.new(name: "Overdue Urgent", priority: "urgent", due_at: @today - 1.day, created_at: 2.days.ago)
    overdue_high = Task.new(name: "Overdue High", priority: "high", due_at: @today - 1.day, created_at: 2.days.ago)
    overdue_med = Task.new(name: "Overdue Med", priority: "medium", due_at: @today - 1.day, created_at: 2.days.ago)
    overdue_low = Task.new(name: "Overdue Low", priority: "low", due_at: @today - 1.day, created_at: 2.days.ago)

    ranked = TaskPriorityScorer.rank([overdue_low, overdue_urgent, overdue_med, overdue_high], reference_date: @today)

    assert_equal [overdue_urgent, overdue_high, overdue_med, overdue_low], ranked
  end

  test "internal ordering within due today tasks respects priority" do
    today_urgent = Task.new(name: "Today Urgent", priority: "urgent", due_at: @today.noon, created_at: 2.days.ago)
    today_high = Task.new(name: "Today High", priority: "high", due_at: @today.noon, created_at: 2.days.ago)
    today_med = Task.new(name: "Today Med", priority: "medium", due_at: @today.noon, created_at: 2.days.ago)

    ranked = TaskPriorityScorer.rank([today_med, today_urgent, today_high], reference_date: @today)

    assert_equal [today_urgent, today_high, today_med], ranked
  end

  test "below overdue and today, priority takes the lead over upcoming low deadlines" do
    urgent_undated = Task.new(name: "Urgent Undated", priority: "urgent", due_at: nil, created_at: 1.day.ago)
    high_tomorrow = Task.new(name: "High Tomorrow", priority: "high", due_at: @today + 1.day, created_at: 1.day.ago)
    low_tomorrow = Task.new(name: "Low Tomorrow", priority: "low", due_at: @today + 1.day, created_at: 1.day.ago)

    ranked = TaskPriorityScorer.rank([low_tomorrow, urgent_undated, high_tomorrow], reference_date: @today)

    assert_equal [urgent_undated, high_tomorrow, low_tomorrow], ranked
  end

  test "within the same priority tier, closer deadlines rank higher than distant deadlines or undated tasks" do
    high_tomorrow = Task.new(name: "High Tomorrow", priority: "high", due_at: @today + 1.day, created_at: 1.day.ago)
    high_soon = Task.new(name: "High in 3 days", priority: "high", due_at: @today + 3.days, created_at: 1.day.ago)
    high_distant = Task.new(name: "High in 2 weeks", priority: "high", due_at: @today + 14.days, created_at: 1.day.ago)
    high_undated = Task.new(name: "High Undated", priority: "high", due_at: nil, created_at: 1.day.ago)

    ranked = TaskPriorityScorer.rank([high_distant, high_undated, high_tomorrow, high_soon], reference_date: @today)

    assert_equal [high_tomorrow, high_soon, high_distant, high_undated], ranked
  end

  test "breaks ties stably by oldest deadline then oldest created_at" do
    time1 = Time.zone.parse("2026-11-01 10:00:00")
    time2 = Time.zone.parse("2026-11-02 10:00:00")

    task1 = Task.new(name: "Earlier Created", priority: "high", due_at: @today + 2.days, created_at: time1)
    task2 = Task.new(name: "Later Created", priority: "high", due_at: @today + 2.days, created_at: time2)

    ranked = TaskPriorityScorer.rank([task2, task1], reference_date: @today)
    assert_equal [task1, task2], ranked
  end

  test "assigns concise explainability reasons" do
    overdue_task = Task.new(name: "Overdue", priority: "high", due_at: @today - 2.days, created_at: 1.day.ago)
    today_task = Task.new(name: "Today", priority: "medium", due_at: @today.noon, created_at: 1.day.ago)
    tomorrow_task = Task.new(name: "Tomorrow", priority: "medium", due_at: @today + 1.day, created_at: 1.day.ago)
    urgent_undated = Task.new(name: "Urgent Undated", priority: "urgent", due_at: nil, created_at: 1.day.ago)

    TaskPriorityScorer.rank([overdue_task, today_task, tomorrow_task, urgent_undated], reference_date: @today)

    assert_equal "Overdue (2 days)", overdue_task.ranking_reason
    assert_equal "Due today", today_task.ranking_reason
    assert_equal "Due tomorrow", tomorrow_task.ranking_reason
    assert_equal "Urgent priority", urgent_undated.ranking_reason
  end
end
