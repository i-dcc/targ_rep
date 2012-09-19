require 'test_helper'

class SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase

  class MockError < RuntimeError; end

  def setup_for_add_and_process
    @allele1_id = 57
    @allele2_id = 92
    SolrUpdate::Queue::Item.add(@allele1_id, 'delete')
    SolrUpdate::Queue::Item.add(@allele2_id, 'update')

    @item1 = SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(@allele1_id, 'delete')
    @item2 = SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(@allele2_id, 'update')
  end

  context 'SolrUpdate::Queue::Item' do

    should have_db_column(:created_at).of_type(:datetime)
    should have_db_column(:allele_id).of_type(:integer)

    should belong_to(:allele)

    should 'return entries in #earliest_first order' do
      SolrUpdate::Queue::Item.create!(:allele_id => 2, :command_type => 'update', :created_at => '2012-01-02 00:00:00 UTC')
      SolrUpdate::Queue::Item.create!(:allele_id => 1, :command_type => 'update', :created_at => '2012-01-01 00:00:00 UTC')
      SolrUpdate::Queue::Item.create!(:allele_id => 3, :command_type => 'delete', :created_at => '2012-01-03 00:00:00 UTC')

      commands = SolrUpdate::Queue::Item.earliest_first
      assert_equal [1, 2, 3], commands.map(&:allele_id)
    end

    should '#add object reference and command type to the database in order of being added' do
      setup_for_add_and_process

      assert_not_nil @item1
      assert_not_nil @item2
    end

    should 'add only one command per item, removing any that are already present' do
      setup_for_add_and_process
      SolrUpdate::Queue::Item.add(@allele2_id, 'delete')

      assert_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(@allele2_id, 'delete')
    end

    should 'process objects in the order they were added and deletes them' do
      setup_for_add_and_process

      things_processed = []

      SolrUpdate::Queue::Item.process_in_order do |allele_id, command_type|
        things_processed.push([allele_id, command_type])
      end

      assert_equal [[@allele1_id, 'delete'], [@allele2_id, 'update']], things_processed
      assert_nil SolrUpdate::Queue::Item.find_by_id(@item1.id)
      assert_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
    end

    should 'not delete queue item if an exception is raised during processing' do
      setup_for_add_and_process

      assert_raise(MockError) do
        SolrUpdate::Queue::Item.process_in_order do |allele_id, command_type|
          raise MockError if allele_id == @allele2_id
        end
      end

      assert_nil SolrUpdate::Queue::Item.find_by_id(@item1.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
    end

  end
end
