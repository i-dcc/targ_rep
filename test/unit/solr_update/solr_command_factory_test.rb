require 'test_helper'

class SolrUpdate::SolrCommandFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::SolrCommandFactory' do
    should 'format allele type from allele mutation_subtype: #formatted_allele_type' do
      allele = Factory.build :allele
      factory = SolrUpdate::SolrCommandFactory.new(allele)

      allele.mutation_subtype = 'deletion'
      assert_equal 'Deletion', factory.__send__(:formatted_allele_type)

      allele.mutation_subtype = 'targeted_non_conditional'
      assert_equal 'Targeted Non Conditional', factory.__send__(:formatted_allele_type)
    end

    context 'when creating solr command for an allele' do

      setup do
        SolrUpdate::IndexProxy::Gene.stubs(:get_marker_symbol).with('MGI:9999999991').returns('Test1')

        @allele = Factory.create :allele, :design_type => 'Knock Out',
                :mgi_accession_id => 'MGI:9999999991'

        fake_unique_solr_info = [
          {'strain' => 'C57BL/6N', 'allele_symbol_superscript' => 'tm1a(EUCOMM)Wtsi'},
          {'strain' => 'C57BL/6N-A<tm1Brd>/a', 'allele_symbol_superscript' => 'tm1a(EUCOMM)Wtsi'}
        ]

        @allele.es_cells.stubs(:unique_solr_info).returns(fake_unique_solr_info)

        @commands_json = SolrUpdate::SolrCommandFactory.create_solr_command(@allele)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete, add and commit in that order' do
        assert_equal %w{delete add commit}, @commands.keys
      end

      should 'delete all docs for tha allele before adding them' do
        assert_equal "type:allele AND id:#{@allele.id}", @commands['delete']['query']
      end

      context 'the add commands' do
        should 'set allele id' do
          assert_equal [@allele.id, @allele.id], @commands['add'].map {|d| d['id']}
        end

        should 'set type' do
          assert_equal ['allele', 'allele'], @commands['add'].map {|d| d['type']}
        end

        should 'set allele_type' do
          assert_equal ['Conditional Ready', 'Conditional Ready'], @commands['add'].map {|d| d['allele_type']}
        end

        should 'set strain'
      end
    end

    should 'create solr command for an es_cell'
  end
end
