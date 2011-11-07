Thingsmattchandlersaid::Application.routes.draw do

  match 'query' => 'search#results'
  match 'search' => 'search#index'
  match 'recent' => 'search#recent'
  match 'queries' => 'search#queries'

  root :to => "search#index"
end
