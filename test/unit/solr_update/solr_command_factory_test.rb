require 'test_helper'

class SolrUpdate::SolrCommandFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::SolrCommandFactory' do
    context 'when creating solr command for an allele' do

      setup do
        SolrUpdate::IndexProxy::Gene.stubs(:get_marker_symbol).with('MGI:9999999991').returns('Test1')

        eucomm = Pipeline.find_or_create_by_name('EUCOMM')
        @allele = Factory.create :allele, :mutation_subtype => 'conditional_ready',
                :mgi_accession_id => 'MGI:9999999991'
        @es_cell1 = Factory.create :es_cell, :allele => @allele, :parental_cell_line => 'VGB6', :pipeline => eucomm
        @es_cell2 = Factory.create :es_cell, :allele => @allele, :parental_cell_line => 'JM8A3.N1', :pipeline => eucomm
        assert_equal 'C57BL/6N', @es_cell1.strain
        assert_equal 'C57BL/6N-A<tm1Brd>/a', @es_cell2.strain

        @commands_json = SolrUpdate::SolrCommandFactory.create_solr_command(@allele)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete, add and commit in that order' do
        assert_equal %w{delete add commit}, @commands.keys
      end

      should 'set allele id'

      should 'set type'

      should 'set allele_type'

      should 'set strain'
    end

    should 'create solr command for an es_cell'
  end
end
