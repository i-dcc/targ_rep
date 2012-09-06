require 'test_helper'

class SolrUpdatingIntegrationTest < ActiveSupport::TestCase
  context 'SOLR updating infrastructure' do

    should 'queue update for an updated allele to the SOLR index' do
      eucomm = Pipeline.find_or_create_by_name('EUCOMM')
      allele = Factory.create :allele, :mutation_subtype => 'conditional_ready'
      es_cell = Factory.create :es_cell, :allele => allele, :strain => 'Blue', :pipeline => eucomm
      es_cell = Factory.create :es_cell, :allele => allele, :strain => 'Red', :pipeline => eucomm
      allele = es_cell.allele

      SolrUpdating::SolrDocSet.destroy_all

      allele.mutation_subtype = 'deletion'
      allele.save!

      docs = [
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'allele_type' => 'Deletion',
          'strain' => 'Blue',
          'allele_name' => "#{es_cell.marker_symbol}<sup>es_cell.allele_symbol_superscript</sup>",
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genebank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_url' => 'http://www.eummcr.org/order.php'
        },
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'allele_type' => 'Deletion',
          'strain' => 'Red',
          'allele_name' => "#{es_cell.marker_symbol}<sup>es_cell.allele_symbol_superscript</sup>",
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genebank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_url' => 'http://www.eummcr.org/order.php'
        }
      ]

      commands = [
        {'delete' => {'query' => "id:#{allele.id},type:allele"} },
        {'add' => {'doc' => docs}}
      ]

      SolrUpdating::IndexProxy.expects(:send).with(commands)

      SolrUpdating::Queue.run
    end

  end
end
