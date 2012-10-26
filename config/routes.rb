ActionController::Routing::Routes.draw do |map|
  map.resources :user_sessions
  map.resources :users
  map.resources :pipelines
  map.resources :alleles, :member => { :history => :get }
  map.resources :genbank_files
  map.resources :targeting_vectors
  map.resources :es_cells, :collection => { :bulk_edit => [:get,:post], :update_multiple => :put }
  map.resources :distribution_qc

  map.escell_clone_genbank_file     '/alleles/:id/escell-clone-genbank-file',      :controller => "alleles", :action => "escell_clone_genbank_file"
  map.targeting_vector_genbank_file '/alleles/:id/targeting-vector-genbank-file',  :controller => "alleles", :action => "targeting_vector_genbank_file"

  map.escell_clone_cre_genbank_file     '/alleles/:id/escell-clone-cre-genbank-file',      :controller => "alleles", :action => "escell_clone_cre_genbank_file"
  map.targeting_vector_cre_genbank_file     '/alleles/:id/targeting-vector-cre-genbank-file',      :controller => "alleles", :action => "targeting_vector_cre_genbank_file"
  map.escell_clone_flp_genbank_file     '/alleles/:id/escell-clone-flp-genbank-file',      :controller => "alleles", :action => "escell_clone_flp_genbank_file"
  map.targeting_vector_flp_genbank_file     '/alleles/:id/targeting-vector-flp-genbank-file',      :controller => "alleles", :action => "targeting_vector_flp_genbank_file"
  map.escell_clone_flp_cre_genbank_file     '/alleles/:id/escell-clone-flp-cre-genbank-file',      :controller => "alleles", :action => "escell_clone_flp_cre_genbank_file"
  map.targeting_vector_flp_cre_genbank_file     '/alleles/:id/targeting-vector-flp-cre-genbank-file',      :controller => "alleles", :action => "targeting_vector_flp_cre_genbank_file"

  map.allele_image   '/alleles/:id/allele-image', :controller => "alleles", :action => "allele_image"
  map.allele_image_cre   '/alleles/:id/allele-image-cre', :controller => "alleles", :action => "allele_image_cre"
  map.allele_image_flp   '/alleles/:id/allele-image-flp', :controller => "alleles", :action => "allele_image_flp"
  map.allele_image_flp_cre   '/alleles/:id/allele-image-flp-cre', :controller => "alleles", :action => "allele_image_flp_cre"
  map.cassette_image   '/alleles/:id/cassette-image', :controller => "alleles", :action => "cassette_image"
  map.vector_image   '/alleles/:id/vector-image', :controller => "alleles", :action => "vector_image"

  map.vector_image_cre   '/alleles/:id/vector-image-cre', :controller => "alleles", :action => "vector_image_cre"
  map.vector_image_flp   '/alleles/:id/vector-image-flp', :controller => "alleles", :action => "vector_image_flp"
  map.vector_image_flp_cre   '/alleles/:id/vector-image-flp-cre', :controller => "alleles", :action => "vector_image_flp_cre"

  map.login  "login",  :controller => "user_sessions", :action => "new"
  map.logout "logout", :controller => "user_sessions", :action => "destroy"

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':controller/:action.:format'

  map.root :controller => "welcome"
end
