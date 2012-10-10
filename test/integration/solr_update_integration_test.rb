require 'test_helper'

class SolrUpdateIntegrationTest < ActiveSupport::TestCase
  context 'SOLR update system' do

    setup do
      @allele_index_proxy = SolrUpdate::IndexProxy::Allele.new

      # TODO Make this with a 'CommandFactory' or something
      commands = ActiveSupport::OrderedHash.new
      commands['delete'] = {'query' => '*:*'}
      commands['commit'] = {}
      commands_json = commands.to_json
      @allele_index_proxy.update(commands_json)

      fetched_docs = @allele_index_proxy.search(:q => 'type:allele')
      assert fetched_docs.blank?, 'docs were not destroyed!'

      eucomm = Pipeline.find_or_create_by_name('EUCOMM')
      @allele = Factory.create :allele, :mutation_type => MutationType.find_by_code('cki'),
              :mgi_accession_id => 'MGI:105369'
      @es_cell1 = Factory.create(:es_cell,
        :allele => @allele, :parental_cell_line => 'VGB6',
        :pipeline => eucomm,
        :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi')
      @es_cell2 = Factory.create(:es_cell,
        :allele => @allele,
        :parental_cell_line => 'JM8A3.N1',
        :pipeline => eucomm,
        :allele_symbol_superscript => 'tm2a(EUCOMM)Wtsi')
      @allele.reload

      assert_equal 'cki', @allele.mutation_type.code
      assert_equal 'C57BL/6N', @allele.es_cells[0].strain
      assert_equal 'C57BL/6N-A<tm1Brd>/a', @allele.es_cells[1].strain
    end

    should_if_solr 'update the SOLR index when an allele is modified' do
      SolrUpdate::Queue::Item.destroy_all

      allele = @allele
      es_cell1 = @es_cell1
      es_cell2 = @es_cell2

      allele.mutation_type = MutationType.find_by_code('tnc')
      allele.save!
      assert_equal 'tnc', allele.mutation_type.code

      docs = [
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'allele_type' => 'Targeted Non Conditional',
          'allele_id' => allele.id,
          'mgi_accession_id' => 'MGI:105369',
          'strain' => es_cell1.strain,
          'allele_name' => 'Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>',
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genbank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_from_url' => 'http://www.eummcr.org/order.php',
          'order_from_name' => 'EUMMCR'
        },
        {
          'id' => allele.id,
          'type' => 'allele',
          'product_type' => 'ES Cell',
          'mgi_accession_id' => 'MGI:105369',
          'allele_type' => 'Targeted Non Conditional',
          'allele_id' => allele.id,
          'strain' => es_cell2.strain,
          'allele_name' => 'Cbx1<sup>tm2a(EUCOMM)Wtsi</sup>',
          'allele_image_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/allele-image",
          'genbank_file_url' => "http://www.knockoutmouse.org/targ_rep/alleles/#{allele.id}/escell-clone-genbank-file",
          'order_from_url' => 'http://www.eummcr.org/order.php',
          'order_from_name' => 'EUMMCR'
        }
      ]

      SolrUpdate::Queue.run

      fetched_docs = @allele_index_proxy.search(:q => 'type:allele')
      fetched_docs.each {|d| d.delete('score')}

      docs.zip(fetched_docs).each do |doc, fetched_doc|
        doc.keys.each do |key|
          assert_equal doc[key], fetched_doc[key], "#{key} expected to be #{doc[key]}, but was #{fetched_doc[key]}"
        end
      end

      assert_equal docs, fetched_docs
    end

    should_if_solr 'update the SOLR index for the entire set of allele docs when an one of its ES cells is modified' do
      SolrUpdate::Queue::Item.destroy_all

      @es_cell1.allele_symbol_superscript = 'tm1b(EUCOMM)Wtsi'
      @es_cell1.save!

      SolrUpdate::Queue.run

      fetched_docs = @allele_index_proxy.search(:q => 'type:allele')
      fetched_docs.each {|d| d.delete('score')}

      allele_symbol_superscripts = fetched_docs.map do |fetched_doc|
        fetched_doc.fetch 'allele_name'
      end
      expected = [
        'Cbx1<sup>tm1b(EUCOMM)Wtsi</sup>',
        'Cbx1<sup>tm2a(EUCOMM)Wtsi</sup>'
      ]
      assert_equal expected, allele_symbol_superscripts.sort
    end

    should_if_solr 'update SOLR docs in index for alleles when one of their ES cells are deleted from the DB' do
      SolrUpdate::Queue.run

      @es_cell2.destroy

      SolrUpdate::Queue.run

      fetched_docs = @allele_index_proxy.search(:q => 'type:allele')
      fetched_docs.each {|d| d.delete('score')}
      assert_equal 1, fetched_docs.size
      assert_equal 'Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>', fetched_docs.first['allele_name']
    end

    should_if_solr 'delete SOLR docs in index for alleles that are deleted from the DB' do
      SolrUpdate::Queue.run

      @allele.destroy

      SolrUpdate::Queue.run

      fetched_docs = @allele_index_proxy.search(:q => 'type:allele')
      fetched_docs.each {|d| d.delete('score')}
      assert_equal 0, fetched_docs.size
    end

  end
end
