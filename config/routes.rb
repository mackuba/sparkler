Rails.application.routes.draw do
  root 'feeds#index'

  resources :feeds

  get '/feed/:id' => 'feeds#show'
end
