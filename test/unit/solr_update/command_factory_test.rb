require 'test_helper'

class SolrUpdate::CommandFactoryTest < ActiveSupport::TestCase

  context 'SolrUpdate::CommandFactory' do

    context 'when creating solr command for an allele that was updated' do

      setup do
        @allele = Factory.create :allele, :design_type => 'Knock Out',
                :mgi_accession_id => 'MGI:9999999991'

        fake_unique_public_info = [
          {:strain => 'C57BL/6N', :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi', :pipeline => 'EUCOMM'},
          {:strain => 'C57BL/6N-A<tm1Brd>/a', :allele_symbol_superscript => 'tm2a(EUCOMM)Wtsi', :pipeline => 'EUCOMMTools'}
        ]

        es_cells = stub('es_cells')
        es_cells.stubs(:unique_public_info).returns(fake_unique_public_info)
        Allele.any_instance.stubs(:es_cells => es_cells)

        fake_docs = [{'allele_doc' => 1}, {'allele_doc' => 2}]
        SolrUpdate::DocFactory.expects(:create_for).with('allele', @allele).returns(fake_docs)

        @commands_json = SolrUpdate::CommandFactory.create_solr_command_to_update_in_index(@allele.id)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete, add and commit in that order' do
        assert_equal %w{delete add commit}, @commands.keys
      end

      should 'delete all docs for that allele before adding them' do
        assert_equal "type:allele AND id:#{@allele.id}", @commands['delete']['query']
      end

      should 'add new docs for that allele' do
        assert_equal [{'allele_doc' => 1}, {'allele_doc' => 2}], @commands['add']
      end

      should 'do a commit after adding new docs' do
        assert_equal({}, @commands['commit'])
      end
    end

    context 'when creating SOLR command for an allele that was deleted' do
      setup do
        @commands_json = SolrUpdate::CommandFactory.create_solr_command_to_delete_from_index(55)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete and commit in that order' do
        assert_equal %w{delete commit}, @commands.keys
      end

      should 'delete all docs for that allele' do
        assert_equal "type:allele AND id:55", @commands['delete']['query']
      end

      should 'do a commit after adding new docs' do
        assert_equal({}, @commands['commit'])
      end
    end

  end
end
