Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "tasks#index"

  resources :tasks, only: %i[new create edit update destroy] do
    patch :toggle_completion, on: :member
  end

  resources :categories, only: %i[index]
end
