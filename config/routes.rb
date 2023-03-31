Rails.application.routes.draw do
  get '/', to: 'test#top'
  get '/search', to: 'test#search'
  get '/result', to: 'test#result'
  get '/map', to: 'test#map'
  get '/test', to: 'test#test'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
