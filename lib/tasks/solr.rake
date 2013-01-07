load "#{Gem.searcher.find('mpi2_solr_update').full_gem_path}/lib/tasks/solr.rake"

namespace :solr do
  desc 'enqueue all alleles for solr update'
  task 'update:enqueue:all' => [:environment] do
    enqueuer = SolrUpdate::Enqueuer.new
    Allele.all.each { |a| enqueuer.allele_updated(a) }
  end

  task 'update:run_queue:all' => [:environment] do
    SolrUpdate::Queue.run(:limit => nil)
  end

  desc 'Sync every Allele and EsCell with the SOLR index'
  task 'update:all' => ['update:enqueue:all', 'update:run_queue:all']
end
