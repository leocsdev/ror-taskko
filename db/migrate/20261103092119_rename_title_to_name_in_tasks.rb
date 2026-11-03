class RenameTitleToNameInTasks < ActiveRecord::Migration[8.1]
  def change
    rename_column :tasks, :title, :name
  end
end
