load "#{Gem.searcher.find('mpi2_solr_update').full_gem_path}/lib/tasks/solr.rake"

namespace :solr do
  desc 'Sync every Allele and EsCell with the SOLR index'
  task 'update:all' => [:environment] do
    enqueuer = SolrUpdate::Enqueuer.new
    Allele.all.each { |a| enqueuer.allele_updated(a) }
    SolrUpdate::Queue.run(:limit => nil)
  end
end
