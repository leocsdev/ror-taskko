class Category < ApplicationRecord
  # When a category is deleted, set the category_id of its tasks to null
  has_many :tasks, dependent: :nullify
  # When a category is deleted, set the ai_suggested_category_id of its tasks to null
  has_many :ai_suggested_tasks, class_name: 'Task', foreign_key: 'ai_suggested_category_id', dependent: :nullify
end
