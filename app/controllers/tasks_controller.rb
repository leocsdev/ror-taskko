class TasksController < ApplicationController
  def index
    @tasks = Task.all
    @active_tasks_count = Task.where(completed_at: nil).count
  end
end
