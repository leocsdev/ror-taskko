class TasksController < ApplicationController
  def index
    @tasks = Task.all
    @active_tasks_count = Task.where(completed_at: nil).count
  end

  def new
    @task = Task.new
    load_categories
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      respond_to do |format|
        format.turbo_stream do
          @tasks = Task.all
          @active_tasks_count = Task.where(completed_at: nil).count
        end
        format.html { redirect_to root_path, status: :see_other }
      end
    else
      load_categories
      respond_to do |format|
        format.turbo_stream { render :new, formats: [ :html ], status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  private

  def task_params
    params.require(:task).permit(:name, :description, :category_id, :priority, :due_at)
  end

  def load_categories
    @categories = Category.order(:name)
  end
end
