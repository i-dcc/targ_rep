require 'test_helper'

class SolrUpdateIntegrationTest < ActiveSupport::TestCase
  context 'SOLR update system' do

    should 'queue update for an updated allele to the SOLR index' do
      allele_index_proxy = SolrUpdate::IndexProxy::Allele.new

      # TODO Make this with a 'CommandFactory' or something
      commands = ActiveSupport::OrderedHash.new
      commands['delete'] = {'query' => '*:*'}
      commands['commit'] = {}
      commands_json = commands.to_json
      allele_index_proxy.update(commands_json)

      fetched_docs = allele_index_proxy.search(:q => 'type:allele')
      assert fetched_docs.blank?, 'docs were not destroyed!'

      eucomm = Pipeline.find_or_create_by_name('EUCOMM')
      allele = Factory.create :allele, :design_type => 'Insertion',
              :mgi_accession_id => 'MGI:105369'
      es_cell1 = Factory.create(:es_cell,
        :allele => allele, :parental_cell_line => 'VGB6',
        :pipeline => eucomm,
        :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi')
      es_cell2 = Factory.create(:es_cell,
        :allele => allele,
        :parental_cell_line => 'JM8A3.N1',
        :pipeline => eucomm,
        :allele_symbol_superscript => 'tm2a(EUCOMM)Wtsi')
      allele.reload

      assert_equal 'insertion', allele.mutation_subtype
      assert_equal 'C57BL/6N', allele.es_cells[0].strain
      assert_equal 'C57BL/6N-A<tm1Brd>/a', allele.es_cells[1].strain

      SolrUpdate::SolrCommand.destroy_all

      allele.design_type = 'Knock Out'
      allele.save!
      assert_equal 'targeted_non_conditional', allele.mutation_subtype

      docs = [
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'allele_type' => 'Targeted Non Conditional',
          'strain' => es_cell1.strain,
          'allele_name' => "Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>",
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genbank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_url' => 'http://www.eummcr.org/order.php'
        },
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'allele_type' => 'Targeted Non Conditional',
          'strain' => es_cell2.strain,
          'allele_name' => "Cbx1<sup>tm2a(EUCOMM)Wtsi</sup>",
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genbank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_url' => 'http://www.eummcr.org/order.php'
        }
      ]

      SolrUpdate::Queue.run

      fetched_docs = allele_index_proxy.search(:q => 'type:allele')
      fetched_docs.each {|d| d.delete('score')}

      docs.zip(fetched_docs).each do |doc, fetched_doc|
        doc.keys.each do |key|
          assert_equal doc[key], fetched_doc[key], "#{key} expected to be #{doc[key]}, but was #{fetched_doc[key]}"
        end
      end

      assert_equal docs, fetched_docs
    end

  end
end
