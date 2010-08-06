ActionController::Routing::Routes.draw do |map|
  map.resources :user_sessions
  map.resources :users
  map.resources :pipelines
  map.resources :alleles, :member => { :history => :get }
  map.resources :genbank_files
  map.resources :targeting_vectors
  map.resources :es_cells, :collection => { :bulk_edit => [:get,:post], :update_multiple => :put }
  
  map.escell_clone_genbank_file     '/alleles/:id/escell-clone-genbank-file',      :controller => "alleles", :action => "escell_clone_genbank_file"
  map.targeting_vector_genbank_file '/alleles/:id/targeting-vector-genbank-file',  :controller => "alleles", :action => "targeting_vector_genbank_file"
  
  map.allele_image   '/alleles/:id/allele-image', :controller => "alleles", :action => "allele_image"
  map.vector_image   '/alleles/:id/vector-image', :controller => "alleles", :action => "vector_image"
  
  map.login  "login",  :controller => "user_sessions", :action => "new" 
  map.logout "logout", :controller => "user_sessions", :action => "destroy"
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  
  map.root :controller => "welcome"
end
