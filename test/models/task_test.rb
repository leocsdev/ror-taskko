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
#  priority                 :string           default("medium"), not null
#  title                    :string           not null
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
      task = Task.new(title: "Sample Task", priority: priority)
      assert task.valid?, "Expected task with priority #{priority} to be valid"
    end
  end

  test "should reject invalid priorities" do
    task = Task.new(title: "Sample Task", priority: "invalid_priority")
    assert_not task.valid?
    assert_includes task.errors[:priority], "is not included in the list"
  end
end
