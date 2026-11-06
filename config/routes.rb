Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "tasks#index"
  get "today", to: "tasks#index", defaults: { view: "today" }, as: :today

  resources :tasks, only: %i[index new create edit update destroy] do
    patch :toggle_completion, on: :member
  end

  resources :categories, only: %i[index show create edit update destroy]
end
