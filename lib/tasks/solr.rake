namespace :solr do
  desc 'Make the SOLR index up-to-date'
  task :update => [:environment] do
    Allele.all.each { |a| SolrUpdate::Queue.enqueue_for_update(a) }
    SolrUpdate::Queue.run
  end
end
