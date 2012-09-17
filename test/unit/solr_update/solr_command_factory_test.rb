require 'test_helper'

class SolrUpdate::SolrCommandFactoryTest < ActiveSupport::TestCase
  context 'SolrUpdate::SolrCommandFactory' do
    should 'format allele type from allele mutation_subtype: #formatted_allele_type' do
      allele = Factory.build :allele
      factory = SolrUpdate::SolrCommandFactory.new(allele)

      allele.mutation_subtype = 'deletion'
      assert_equal 'Deletion', factory.__send__(:formatted_allele_type)

      allele.mutation_subtype = 'targeted_non_conditional'
      assert_equal 'Targeted Non Conditional', factory.formatted_allele_type
    end

    context 'calculating order_url' do
      setup do
        SolrUpdate::IndexProxy::Gene.any_instance.stubs(:get_marker_symbol).with('MGI:9999999991').returns('Test1')
        allele = Factory.create :allele, :mgi_accession_id => 'MGI:9999999991'
        @factory = SolrUpdate::SolrCommandFactory.new(allele)
      end

      should 'work for one of the EUCOMM pipelines' do
        ['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].each do |pipeline|
          data = {:pipeline => pipeline}
          assert_equal 'http://www.eummcr.org/order.php', @factory.calculate_order_url(data)
        end
      end

      should 'work for one of the KOMP pipelines without a valid project id' do
        ['KOMP-CSD', 'KOMP-Regeneron'].each do |pipeline|
          data = {:pipeline => pipeline, :ikmc_project_id => '123'}
          assert_equal 'http://www.komp.org/geneinfo.php?project=CSD123', @factory.calculate_order_url(data)
        end
      end

      should 'work for one of the KOMP pipelines with a valid project id' do
        ['KOMP-CSD', 'KOMP-Regeneron'].each do |pipeline|
          data = {:pipeline => pipeline, :ikmc_project_id => 'VG10003'}
          assert_equal 'http://www.komp.org/geneinfo.php?project=VG10003', @factory.calculate_order_url(data)
        end
      end

      should 'work for MirKO or Sanger MGP pipelines' do
        ['MirKO', 'Sanger MGP'].each do |pipeline|
          data = {:pipeline => pipeline}
          assert_equal 'mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for Test1', @factory.calculate_order_url(data)
        end
      end

      should 'work for one of the NorCOMM pipeline' do
        data = {:pipeline => 'NorCOMM'}
        assert_equal 'http://www.phenogenomics.ca/services/cmmr/escell_services.html', @factory.calculate_order_url(data)
      end

    end

    context 'when creating solr command for an allele that was updated' do

      setup do
        SolrUpdate::IndexProxy::Gene.any_instance.stubs(:get_marker_symbol).with('MGI:9999999991').returns('Test1')

        @allele = Factory.create :allele, :design_type => 'Knock Out',
                :mgi_accession_id => 'MGI:9999999991'

        fake_unique_public_info = [
          {:strain => 'C57BL/6N', :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi', :pipeline => 'EUCOMM'},
          {:strain => 'C57BL/6N-A<tm1Brd>/a', :allele_symbol_superscript => 'tm2a(EUCOMM)Wtsi', :pipeline => 'EUCOMMTools'}
        ]

        @allele.es_cells.stubs(:unique_public_info).returns(fake_unique_public_info)

        @commands_json = SolrUpdate::SolrCommandFactory.create_solr_command_to_update_in_index(@allele)
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

        should 'set order_url' do
          url = 'http://www.eummcr.org/order.php'
          assert_equal [url, url], @commands['add'].map {|d| d['order_url']}
        end

      end
    end

    context 'when creating SOLR command for an allele that was deleted' do
      setup do
        @allele = Factory.create :allele, :design_type => 'Knock Out',
                :mgi_accession_id => 'MGI:9999999991'

        @commands_json = SolrUpdate::SolrCommandFactory.create_solr_command_to_delete_from_index(@allele)
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
