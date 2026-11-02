class Task < ApplicationRecord
  # A task can exist without being assigned to a category
  belongs_to :category, optional: true

  # A task can exist without an AI suggested category, and the reference points to the categories table
  belongs_to :ai_suggested_category,
             class_name: 'Category',
             optional: true,
             inverse_of: :ai_suggested_tasks
end
