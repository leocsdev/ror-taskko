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
class Task < ApplicationRecord
  # A task can exist without being assigned to a category
  belongs_to :category, optional: true

  # A task can exist without an AI suggested category, and the reference points to the categories table
  belongs_to :ai_suggested_category,
             class_name: "Category",
             optional: true,
             inverse_of: :ai_suggested_tasks
end
