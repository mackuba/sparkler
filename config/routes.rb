Rails.application.routes.draw do
  root 'feeds#index'

  resources :feeds do
    resources :statistics

    get :reload, on: :member
  end
end
