class TasksController < ApplicationController
  before_action :set_task, only: %i[edit update toggle_completion destroy]
  before_action :load_categories, only: %i[index new edit create update]

  def index
    load_tasks
  end

  def new
    @task = Task.new
  end

  def edit
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      respond_to do |format|
        format.turbo_stream { load_tasks }
        format.html { redirect_to root_path, status: :see_other }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @task.update(task_params)
      respond_to do |format|
        format.turbo_stream { load_tasks }
        format.html { redirect_to root_path, status: :see_other }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def toggle_completion
    completed_at = @task.completed? ? nil : Time.current
    @task.update!(completed_at: completed_at)

    respond_to do |format|
      format.turbo_stream { load_tasks }
      format.html { redirect_to root_path, status: :see_other }
    end
  end

  def destroy
    @task.destroy!

    respond_to do |format|
      format.turbo_stream { load_tasks }
      format.html { redirect_to root_path, status: :see_other }
    end
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:name, :description, :category_id, :priority, :due_at)
  end

  def load_categories
    @categories = Category.order(:name)
  end

  def load_tasks
    @total_tasks_count = Task.count
    @active_tasks_count = Task.active.count
    @completed_tasks_count = Task.completed.count

    @tasks = Task.includes(:category)
                .by_status(params[:status])
                .by_category(params[:category_id])
                .by_priority(params[:priority])
                .ordered
  end
end
