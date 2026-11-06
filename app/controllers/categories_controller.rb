class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show edit update destroy]

  def index
    categories_with_count

    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to categories_path, status: :see_other }
      end
    else
      categories_with_count

      respond_to do |format|
        format.turbo_stream { render :new, status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    if @category.update(category_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to categories_path, status: :see_other }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to categories_path, status: :see_other, notice: "Category deleted." }
    end
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end

  def set_category
    @category = Category.find(params[:id])
  end

  def categories_with_count
    @categories = Category.with_tasks_count.order(:name)
  end
end
