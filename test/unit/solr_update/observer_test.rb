require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase
  context 'SolrUpdate::Observer::Allele' do

    should 'enqueue a solr update when an allele changes' do
      allele = stub('allele')
      SolrUpdate::Enqueuer.any_instance.expects(:allele_updated).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_save allele
    end

    should 'enqueue a solr deletion when an allele destroyed' do
      allele = stub('allele')
      SolrUpdate::Enqueuer.any_instance.expects(:allele_destroyed).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_destroy allele
    end
  end

  context 'SolrUpdate::Observer::EsCell' do
    should 'enqueue a solr update an es_cell changes' do
      es_cell = stub('es_cell')

      SolrUpdate::Enqueuer.any_instance.expects(:es_cell_updated).with(es_cell)

      o = SolrUpdate::Observer::EsCell.new
      o.after_save es_cell
    end

    should 'enqueue a solr update when es_cell is deleted' do
      es_cell = stub('es_cell')

      SolrUpdate::Enqueuer.any_instance.expects(:es_cell_destroyed).with(es_cell)

      o = SolrUpdate::Observer::EsCell.new
      o.after_destroy es_cell
    end

  end
end
