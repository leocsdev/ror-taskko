class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.string :priority
      t.datetime :due_at
      t.datetime :completed_at
      t.string :ai_suggested_priority
      t.text :ai_reason
      t.string :ai_status
      t.datetime :ai_analyzed_at

      # A task can exist without being assigned to a category
      t.references :category, null: true, foreign_key: true
      # A task can exist without an AI suggested category, and the reference points to the categories table
      t.references :ai_suggested_category, null: true, foreign_key: { to_table: :categories }

      t.timestamps
    end
  end
end
