ActionController::Routing::Routes.draw do |map|
  map.resources :user_sessions
  map.resources :users
  map.resources :pipelines
  map.resources :genbank_files
  map.resources :molecular_structures, :as => "alleles"
  map.resources :targeting_vectors
  map.resources :es_cells
  
  map.escell_clone_genbank_file     '/alleles/:id/escell-clone-genbank-file',      :controller => "molecular_structures", :action => "get_escell_clone_genbank_file"
  map.targeting_vector_genbank_file '/alleles/:id/targeting-vector-genbank-file',  :controller => "molecular_structures", :action => "get_targeting_vector_genbank_file"
  map.allele_image                  '/alleles/:id/allele-image',                   :controller => "molecular_structures", :action => "get_allele_image"
  map.vector_image                  '/alleles/:id/vector-image',                   :controller => "molecular_structures", :action => "get_vector_image"
  
  map.login  "login",  :controller => "user_sessions", :action => "new" 
  map.logout "logout", :controller => "user_sessions", :action => "destroy"
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  map.root :controller => "welcome"
end
