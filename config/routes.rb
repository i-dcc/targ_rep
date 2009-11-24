ActionController::Routing::Routes.draw do |map|
  map.resources :user_sessions
  map.resources :users
  map.resources :pipelines
  map.resources :genbank_files
  map.resources :molecular_structures
  map.resources :targeting_vectors
  map.resources :es_cells
  
  map.login  "login",  :controller => "user_sessions", :action => "new" 
  map.logout "logout", :controller => "user_sessions", :action => "destroy"
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  map.root :controller => "welcome"
end
