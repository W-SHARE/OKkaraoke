Rails.application.routes.draw do
  devise_for :users
  get '/', to: 'home#index'
  get '/search', to: 'search#search'
  get '/result', to: 'search#result'
  get '/map', to: 'search#map'
  get '/information', to: 'home#information'
  #get '/contact', to: 'home#contact'
  

end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
