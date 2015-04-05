Rails.application.routes.draw do
  root 'feeds#index'

  resources :feeds do
    get :reload, on: :member
  end
end
