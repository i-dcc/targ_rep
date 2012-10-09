require 'test_helper'

class SolrUpdate::EnqueuerTest < ActiveSupport::TestCase
  context 'SolrUpdate::Enqueuer' do

    setup do
      @allele = stub('allele', :id => 44)
      @es_cell = stub('es_cell', :id => 642, :allele => @allele)
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    should 'enqueue an allele to be updated in Solr when it changes' do
      SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'allele', 'id' => 44})
      @enqueuer.allele_updated(@allele)
    end

    should 'enqueue an allele for deletion from Solr when it is destroyed' do
      SolrUpdate::Queue.expects(:enqueue_for_delete).with({'type' => 'allele', 'id' => 44})
      @enqueuer.allele_destroyed(@allele)
    end

    should 'enqueue it\'s allele to be updated in Solr when an es_cell changes' do
      SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'allele', 'id' => 44})
      @enqueuer.es_cell_updated(@es_cell)
    end

    should 'enqueue it\'s allele to be updated in Solr when an es_cell is destroyed' do
      SolrUpdate::Queue.expects(:enqueue_for_update).with({'type' => 'allele', 'id' => 44})
      @enqueuer.es_cell_destroyed(@es_cell)
    end

  end
end
