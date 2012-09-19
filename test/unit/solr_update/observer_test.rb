require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase
  context 'SolrUpdate::Observer::Allele' do

    should 'activate a solr doc update for an allele when it changes' do
      allele = stub('allele')
      SolrUpdate::Queue.expects(:enqueue_for_update).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_save allele
    end

    should 'activate a solr doc deletion for an allele when it is destroyed' do
      allele = stub('allele')
      SolrUpdate::Queue.expects(:enqueue_for_delete).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_destroy allele
    end
  end

  context 'SolrUpdate::Observer::EsCell' do
    should 'activate a solr update for it\'s allele when an es_cell changes' do
      allele = stub('allele')
      es_cell = stub('es_cell', :allele => allele)

      SolrUpdate::Queue.expects(:enqueue_for_update).with(allele)

      o = SolrUpdate::Observer::EsCell.new
      o.after_save es_cell
    end

    should 'activate a solr update for it\'s allele when an es_cell is deleted' do
      allele = stub('allele')
      es_cell = stub('es_cell', :allele => allele)

      SolrUpdate::Queue.expects(:enqueue_for_update).with(allele)

      o = SolrUpdate::Observer::EsCell.new
      o.after_destroy es_cell
    end

  end
end
