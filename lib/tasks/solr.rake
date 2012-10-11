namespace :solr do
  desc 'Sync every Allele and EsCell with the SOLR index'
  task 'update:all' => [:environment] do
    Allele.all.each { |a| SolrUpdate::Queue.enqueue_for_update(a) }
    SolrUpdate::Queue.run(:limit => nil)
  end

  desc 'Run the SOLR update queue to send recent changes to the index'
  task 'update' => [:environment] do
    SolrUpdate::Queue.run
  end
end
