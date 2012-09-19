namespace :solr do
  desc 'Make the SOLR index up-to-date'
  task :update => [:environment] do
    Allele.all.each { |a| SolrUpdate::Activator.update_allele_solr_docs(a) }
    SolrUpdate::Queue.run
  end
end
