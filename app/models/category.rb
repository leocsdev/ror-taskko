# == Schema Information
#
# Table name: categories
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_categories_on_lower_name  (lower((name)::text)) UNIQUE
#
class Category < ApplicationRecord
  # When a category is deleted, set the category_id of its tasks to null
  has_many :tasks, dependent: :nullify

  # When a category is deleted, set the ai_suggested_category_id of its tasks to null
  has_many :ai_suggested_tasks,
           class_name: "Task",
           foreign_key: "ai_suggested_category_id",
           dependent: :nullify,
           inverse_of: :ai_suggested_category

  # Validate case-insensitive uniqueness of name
  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
