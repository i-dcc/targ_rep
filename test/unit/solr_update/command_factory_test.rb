require 'test_helper'

class SolrUpdate::CommandFactoryTest < ActiveSupport::TestCase

  context 'SolrUpdate::CommandFactory' do

    setup do
      SolrUpdate::IndexProxy::Gene.any_instance.stubs(:get_marker_symbol).with('MGI:9999999991').returns('Test1')
    end

    context '::Util' do
      setup do
        @test_object = stub('test_object', :gene_index_proxy => SolrUpdate::IndexProxy::Gene.new)
        @test_object.extend(SolrUpdate::CommandFactory::Util)
        @mock_allele = stub('mock_allele', :mgi_accession_id => 'MGI:9999999991')
        @test_object.stubs(:allele => @mock_allele)
      end

      should 'format allele type from allele mutation_subtype: #formatted_allele_type' do
        @mock_allele.stubs(:mutation_subtype => 'deletion')
        assert_equal 'Deletion', @test_object.formatted_allele_type

        @mock_allele.stubs(:mutation_subtype => 'targeted_non_conditional')
        assert_equal 'Targeted Non Conditional', @test_object.formatted_allele_type
      end

      context 'calculating order_from_url and order_from_link' do
        should 'work for one of the EUCOMM pipelines' do
          expected = {:url => 'http://www.eummcr.org/order.php', :name => 'EUMMCR'}
          ['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].each do |pipeline|
            data = {:pipeline => pipeline}
            assert_equal expected, @test_object.calculate_order_from_info(data)
          end
        end

        should 'work for one of the KOMP pipelines without a valid project id' do
          expected = {:url => 'http://www.komp.org/geneinfo.php?project=CSD123', :name => 'KOMP'}
          ['KOMP-CSD', 'KOMP-Regeneron'].each do |pipeline|
            data = {:pipeline => pipeline, :ikmc_project_id => '123'}
            assert_equal expected, @test_object.calculate_order_from_info(data)
          end
        end

        should 'work for one of the KOMP pipelines with a valid project id' do
          expected = {:url => 'http://www.komp.org/geneinfo.php?project=VG10003', :name => 'KOMP'}
          ['KOMP-CSD', 'KOMP-Regeneron'].each do |pipeline|
            data = {:pipeline => pipeline, :ikmc_project_id => 'VG10003'}
            assert_equal expected, @test_object.calculate_order_from_info(data)
          end
        end

        should 'work for MirKO or Sanger MGP pipelines' do
          expected = {:url => 'mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for Test1', :name => 'Wtsi'}
          ['MirKO', 'Sanger MGP'].each do |pipeline|
            data = {:pipeline => pipeline}
            assert_equal expected, @test_object.calculate_order_from_info(data)
          end
        end

        should 'work for one of the NorCOMM pipeline' do
          data = {:pipeline => 'NorCOMM'}
          expected = {:url => 'http://www.phenogenomics.ca/services/cmmr/escell_services.html', :name => 'NorCOMM'}
          assert_equal expected, @test_object.calculate_order_from_info(data)
        end

      end
    end

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

        @commands_json = SolrUpdate::CommandFactory.create_solr_command_to_update_in_index(@allele.id)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete, add and commit in that order' do
        assert_equal %w{delete add commit}, @commands.keys
      end

      should 'delete all docs for that allele before adding them' do
        assert_equal "type:allele AND id:#{@allele.id}", @commands['delete']['query']
      end

      should 'do a commit after adding new docs' do
        assert_equal({}, @commands['commit'])
      end

      context 'the add commands' do
        should 'set allele_id' do
          assert_equal [@allele.id, @allele.id], @commands['add'].map {|d| d['id']}
        end

        should 'set type' do
          assert_equal ['allele', 'allele'], @commands['add'].map {|d| d['type']}
        end

        should 'set mgi_accession_id' do
          assert_equal ['MGI:9999999991', 'MGI:9999999991'], @commands['add'].map {|d| d['mgi_accession_id']}
        end

        should 'set product_type' do
          assert_equal ['ES Cell', 'ES Cell'], @commands['add'].map {|d| d['product_type']}
        end

        should 'set allele_type' do
          assert_equal ['Conditional Ready', 'Conditional Ready'], @commands['add'].map {|d| d['allele_type']}
        end

        should 'set strain' do
          assert_equal ['C57BL/6N', 'C57BL/6N-A<tm1Brd>/a'], @commands['add'].map {|d| d['strain']}
        end

        should 'set allele_name' do
          assert_equal ['Test1<sup>tm1a(EUCOMM)Wtsi</sup>', 'Test1<sup>tm2a(EUCOMM)Wtsi</sup>'],
                  @commands['add'].map {|d| d['allele_name']}
        end

        should 'set allele_image_url' do
          url = "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/allele-image"
          assert_equal [url, url], @commands['add'].map {|d| d['allele_image_url']}
        end

        should 'set genbank_file_url' do
          url = "http://www.knockoutmouse.org/targ_rep/alleles/#{@allele.id}/escell-clone-genbank-file"
          assert_equal [url, url], @commands['add'].map {|d| d['genbank_file_url']}
        end

        should 'set order_from_url' do
          url = 'http://www.eummcr.org/order.php'
          assert_equal [url, url], @commands['add'].map {|d| d['order_from_url']}
        end

        should 'set order_from_name' do
          assert_equal ['EUMMCR', 'EUMMCR'], @commands['add'].map {|d| d['order_from_name']}
        end

      end
    end

    context 'when creating SOLR command for an allele that was deleted' do
      setup do
        @allele = Factory.create :allele, :design_type => 'Knock Out',
                :mgi_accession_id => 'MGI:9999999991'

        @commands_json = SolrUpdate::CommandFactory.create_solr_command_to_delete_from_index(@allele.id)
        @commands = JSON.parse(@commands_json, :object_class => ActiveSupport::OrderedHash)
      end

      should 'delete and commit in that order' do
        assert_equal %w{delete commit}, @commands.keys
      end

      should 'delete all docs for that allele' do
        assert_equal "type:allele AND id:#{@allele.id}", @commands['delete']['query']
      end

      should 'do a commit after adding new docs' do
        assert_equal({}, @commands['commit'])
      end
    end

  end
end
