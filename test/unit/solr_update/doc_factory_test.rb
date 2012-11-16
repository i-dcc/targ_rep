require 'test_helper'

class SolrUpdate::DocFactoryTest < ActiveSupport::TestCase
  def setup_fake_unique_public_info(list_of_params)
    replacement = list_of_params.map do |params|
      {:strain => 'C57BL/6N', :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi'}.merge(params)
    end

    @fake_unique_public_info.replace replacement
  end

  context 'SolrUpdate::DocFactory' do

    setup do
      SolrUpdate::IndexProxy::Gene.any_instance.stubs(:get_marker_symbol).with('MGI:9999999991').returns('Test1')
    end

    should '#create when reference type is allele' do
      @allele = Factory.create :allele, :id => 55, :mgi_accession_id => 'MGI:9999999991'
      reference = {'type' => 'allele', 'id' => 55}
      test_docs = [{'test' => true}]
      SolrUpdate::DocFactory.expects(:create_for_allele).with(@allele).returns(test_docs)
      assert_equal test_docs, SolrUpdate::DocFactory.create(reference)
    end

    context 'when creating solr docs for allele' do

      setup do
        @allele = Factory.create :allele, :mutation_type => MutationType.find_by_code!('crd'),
                :mgi_accession_id => 'MGI:9999999991'

        @fake_unique_public_info = [
          {:strain => 'C57BL/6N', :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi', :pipeline => 'EUCOMM'},
          {:strain => 'C57BL/6N-A<tm1Brd>/a', :allele_symbol_superscript => 'tm2a(EUCOMM)Wtsi', :pipeline => 'EUCOMMTools'}
        ]

        es_cells = stub('es_cells')
        es_cells.stubs(:unique_public_info).returns(@fake_unique_public_info)
        @allele.stubs(:es_cells).returns(es_cells)

        @docs = SolrUpdate::DocFactory.create_for_allele(@allele)
      end

      should 'set id' do
        assert_equal [@allele.id, @allele.id], @docs.map {|d| d['id']}
      end

      should 'set type' do
        assert_equal ['allele', 'allele'], @docs.map {|d| d['type']}
      end

      should 'set mgi_accession_id' do
        assert_equal ['MGI:9999999991', 'MGI:9999999991'], @docs.map {|d| d['mgi_accession_id']}
      end

      should 'set product_type' do
        assert_equal ['ES Cell', 'ES Cell'], @docs.map {|d| d['product_type']}
      end

      should 'set allele_type' do
        assert_equal ['Conditional Ready', 'Conditional Ready'], @docs.map {|d| d['allele_type']}
        @allele.mutation_type = MutationType.find_by_code!('tnc')
        @docs = SolrUpdate::DocFactory.create_for_allele(@allele)
        assert_equal ['Targeted Non Conditional', 'Targeted Non Conditional'], @docs.map {|d| d['allele_type']}
      end

      should 'set allele_id' do
        assert_equal [@allele.id, @allele.id], @docs.map {|d| d['allele_id']}
      end

      should 'set strain' do
        assert_equal ['C57BL/6N', 'C57BL/6N-A<tm1Brd>/a'], @docs.map {|d| d['strain']}
      end

      should 'set allele_name' do
        assert_equal ['Test1<sup>tm1a(EUCOMM)Wtsi</sup>', 'Test1<sup>tm2a(EUCOMM)Wtsi</sup>'],
                @docs.map {|d| d['allele_name']}
      end

      should 'set allele_image_url' do
        url = "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/allele-image"
        assert_equal [url, url], @docs.map {|d| d['allele_image_url']}
      end

      should 'set genbank_file_url' do
        url = "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/escell-clone-genbank-file"
        assert_equal [url, url], @docs.map {|d| d['genbank_file_url']}
      end

      context 'order_from_urls and order_from_names' do
        should 'be set for any of the EUCOMM pipelines' do
          expected_url = ['http://www.eummcr.org/order.php']
          expected_name = ['EUMMCR']

          setup_fake_unique_public_info [
            {:pipeline => 'EUCOMM'},
            {:pipeline => 'EUCOMMTools'},
            {:pipeline => 'EUCOMMToolsCre'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*3, @docs.map {|d| d['order_from_urls']}
          assert_equal [expected_name]*3, @docs.map {|d| d['order_from_names']}
        end

        should 'work for one of the KOMP pipelines without a valid project id' do
          expected_url = ['http://www.komp.org/geneinfo.php?project=CSD123']
          expected_name = ['KOMP']

          setup_fake_unique_public_info [
            {:pipeline => 'KOMP-CSD', :ikmc_project_id => '123'},
            {:pipeline => 'KOMP-Regeneron', :ikmc_project_id => '123'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for one of the KOMP pipelines with a valid project id' do
          expected_url = ['http://www.komp.org/geneinfo.php?project=VG10003']
          expected_name = ['KOMP']

          setup_fake_unique_public_info [
            {:ikmc_project_id => 'VG10003', :pipeline => 'KOMP-CSD'},
            {:ikmc_project_id => 'VG10003', :pipeline => 'KOMP-Regeneron'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for one of the KOMP pipelines with NO project id' do
          expected_url = ['http://www.komp.org/']
          expected_name = ['KOMP']

          setup_fake_unique_public_info [
            {:pipeline => 'KOMP-CSD'},
            {:pipeline => 'KOMP-Regeneron'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for mirKO or Sanger MGP pipelines' do
          expected_url = ['mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for Test1']
          expected_name = ['Wtsi']

          setup_fake_unique_public_info [
            {:pipeline => 'mirKO'},
            {:pipeline => 'Sanger MGP'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [expected_url]*2, @docs.map{|d| d['order_from_urls']}
          assert_equal [expected_name]*2, @docs.map{|d| d['order_from_names']}
        end

        should 'work for one of the NorCOMM pipeline' do
          expected_url = 'http://www.phenogenomics.ca/services/cmmr/escell_services.html'
          expected_name = 'NorCOMM'

          setup_fake_unique_public_info [
            {:pipeline => 'NorCOMM'}
          ]

          @docs = SolrUpdate::DocFactory.create_for_allele(@allele)

          assert_equal [[expected_url]], @docs.map{|d| d['order_from_urls']}
          assert_equal [[expected_name]], @docs.map{|d| d['order_from_names']}
        end
      end

      should 'set order_from_urls' do
        url = ['http://www.eummcr.org/order.php']
        assert_equal [url, url], @docs.map {|d| d['order_from_urls']}
      end

      should 'set order_from_names' do
        assert_equal [['EUMMCR'], ['EUMMCR']], @docs.map {|d| d['order_from_names']}
      end

    end

  end
end
