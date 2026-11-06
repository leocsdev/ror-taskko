class CategoriesController < ApplicationController
  before_action :set_category, only: %i[show edit update destroy]

  def index
    @categories = Category.all
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to categories_path }
      end
    else
      @categories = Category.all
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
        format.html { redirect_to categories_path }
      end
    else
      # respond_to do |format|
      #   format.turbo_stream { render :edit, formats: [ :html ], status: :unprocessable_entity }
      #   format.html { render :edit, status: :unprocessable_entity }
      # end
      # Let Rails return standard HTML for the Turbo Frame to swap in
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy!
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to categories_path, notice: "Category deleted." }
    end
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end

  def set_category
    @category = Category.find(params[:id])
  end
end
