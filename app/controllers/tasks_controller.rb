class TasksController < ApplicationController
  def index
    @tasks = Task.all
    @active_tasks_count = Task.where(completed_at: nil).count
  end

  def new
    @task = Task.new
    load_categories
  end

  def edit
    @task = Task.find(params[:id])
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
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    @task = Task.find(params[:id])

    if @task.update(task_params)
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
        format.turbo_stream { render :edit, status: :unprocessable_entity }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def toggle_completion
    @task = Task.find(params[:id])
    completed_at = @task.completed_at? ? nil : Time.current
    @task.update!(completed_at: completed_at)

    respond_to do |format|
      format.turbo_stream do
        @tasks = Task.all
        @active_tasks_count = Task.where(completed_at: nil).count
      end
      format.html { redirect_to root_path, status: :see_other }
    end
  end

  def destroy
    @task = Task.find(params[:id])
    @task.destroy!

    respond_to do |format|
      format.turbo_stream do
        @tasks = Task.all
        @active_tasks_count = Task.where(completed_at: nil).count
      end
      format.html { redirect_to root_path, status: :see_other }
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
