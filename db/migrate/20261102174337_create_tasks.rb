class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :priority, default: "medium", null: false
      t.datetime :due_at
      t.datetime :completed_at
      t.string :ai_suggested_priority
      t.text :ai_reason
      t.string :ai_status, default: 'not_requested', null: false
      t.datetime :ai_analyzed_at

      # A task can exist without being assigned to a category
      t.references :category, null: true, foreign_key: true
      # A task can exist without an AI suggested category, and the reference points to the categories table
      t.references :ai_suggested_category, null: true, foreign_key: { to_table: :categories }

      t.timestamps
    end

    # Add check constraints for allowed values of priority, ai_suggested_priority, and ai_status
    add_check_constraint :tasks,
      "priority IN ('low', 'medium', 'high', 'urgent')",
      name: "tasks_priority_allowed_values"

    add_check_constraint :tasks,
      "ai_suggested_priority IS NULL OR ai_suggested_priority IN ('low', 'medium', 'high', 'urgent')",
      name: "tasks_ai_suggested_priority_allowed_values"

    add_check_constraint :tasks,
      "ai_status IN ('not_requested', 'pending', 'completed', 'failed')",
      name: "tasks_ai_status_allowed_values"
  end
end
