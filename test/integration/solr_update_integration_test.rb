require 'test_helper'

class SolrUpdateIntegrationTest < ActiveSupport::TestCase
  context 'SOLR update system' do

    should 'queue update for an updated allele to the SOLR index' do
      SolrUpdate::IndexProxy::Gene.stubs(:get_marker_symbol).with('MGI:9999999991').returns('Test1')

      flunk 'Delete all allele docs for Test1 gene'

      eucomm = Pipeline.find_or_create_by_name('EUCOMM')
      allele = Factory.create :allele, :mutation_subtype => 'conditional_ready',
              :mgi_accession_id => 'MGI:9999999991'
      es_cell1 = Factory.create :es_cell, :allele => allele, :parental_cell_line => 'VGB6', :pipeline => eucomm
      es_cell2 = Factory.create :es_cell, :allele => allele, :parental_cell_line => 'JM8A3.N1', :pipeline => eucomm
      assert_equal 'C57BL/6N', es_cell1.strain
      assert_equal 'C57BL/6N-A<tm1Brd>/a', es_cell2.strain

      allele.mutation_subtype = 'deletion'
      allele.save!

      docs = [
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'allele_type' => 'Deletion',
          'strain' => es_cell2.strain,
          'allele_name' => "Test1<sup>#{es_cell1.allele_symbol_superscript}</sup>",
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genebank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_url' => 'http://www.eummcr.org/order.php'
        },
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'allele_type' => 'Deletion',
          'strain' => es_cell2.strain,
          'allele_name' => "Cbx1<sup>#{es_cell2.allele_symbol_superscript}</sup>",
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genebank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_url' => 'http://www.eummcr.org/order.php'
        }
      ]

      #commands = ActiveSupport::OrderedHash.new
      #commands['delete'] = {'query' => "id:#{allele.id},type:allele"}
      #commands['add'] = docs
      #commands['commit'] = {}
      #commands['optimize'] = {}
      #commands_json = commands.to_json

      SolrUpdate::Queue.run

      flunk 'Get docs for the allele, make sure they are what you expect'
    end

  end
end
