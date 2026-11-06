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
class Task < ApplicationRecord
  PRIORITIES = %w[low medium high urgent].freeze
  AI_STATUSES = %w[not_requested pending completed failed].freeze

  # Scopes
  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(completed_at: nil) }
  scope :completed, -> { where.not(completed_at: nil) }

  scope :by_status, ->(status) {
    case status
    when "active" then active
    when "completed" then completed
    else all
    end
  }

  scope :by_category, ->(category_id) {
    category_id.present? ? where(category_id: category_id) : all
  }

  scope :by_priority, ->(priority) {
    priority.present? && PRIORITIES.include?(priority) ? where(priority: priority) : all
  }

  # A task can exist without being assigned to a category
  belongs_to :category, optional: true

  # A task can exist without an AI suggested category, and the reference points to the categories table
  belongs_to :ai_suggested_category,
             class_name: "Category",
             optional: true,
             inverse_of: :ai_suggested_tasks

  # Validate presence of name
  validates :name, presence: true

  # Validate priority against allowed values
  validates :priority, inclusion: { in: PRIORITIES }

  # Validate AI status against allowed values
  validates :ai_status, inclusion: { in: AI_STATUSES }

  # Validate AI suggested priority against allowed values when present
  validates :ai_suggested_priority,
            inclusion: { in: PRIORITIES },
            allow_nil: true

  # Domain predicates
  def completed?
    completed_at.present?
  end

  def due_today?
    due_at.present? && due_at.to_date == Time.zone.today
  end

  def overdue?
    due_at.present? && due_at.to_date < Time.zone.today && !completed?
  end
end
