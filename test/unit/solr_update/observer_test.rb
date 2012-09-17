require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase
  context 'SolrUpdate::Observer::Allele' do

    should 'activate a solr update for an allele when it changes' do
      allele = stub('allele')
      SolrUpdate::Activator.expects(:update_allele_solr_docs).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_save allele
    end

    should 'activate a solr doc purge for an allele when it is destroyed' do
      allele = stub('allele')
      SolrUpdate::Activator.expects(:delete_allele_solr_docs).with(allele)

      o = SolrUpdate::Observer::Allele.new
      o.after_destroy allele
    end
  end

  context 'SolrUpdate::Observer::EsCell' do
    should 'activate a solr update for it\'s allele when an es_cell changes' do
      allele = stub('allele')
      es_cell = stub('es_cell', :allele => allele)

      SolrUpdate::Activator.expects(:update_allele_solr_docs).with(allele)

      o = SolrUpdate::Observer::EsCell.new
      o.after_save es_cell
    end

    should 'activate a solr update for it\'s allele when an es_cell is deleted' do
      allele = stub('allele')
      es_cell = stub('es_cell', :allele => allele)

      SolrUpdate::Activator.expects(:update_allele_solr_docs).with(allele)

      o = SolrUpdate::Observer::EsCell.new
      o.after_destroy es_cell
    end

  end
end
