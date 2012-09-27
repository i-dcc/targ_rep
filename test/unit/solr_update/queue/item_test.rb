require 'test_helper'

class SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase

  class MockError < RuntimeError; end

  def setup_for_add_and_process
    @allele1_reference = {'type' => 'allele', 'id' => 57}
    @allele2_reference = {'type' => 'allele', 'id' => 92}
    SolrUpdate::Queue::Item.add(@allele1_reference, 'delete')
    SolrUpdate::Queue::Item.add(@allele2_reference, 'update')

    @item1 = SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(@allele1_reference['id'], 'delete')
    @item2 = SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(@allele2_reference['id'], 'update')
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

    should 'add model object directly instead of it\'s id' do
      allele = Factory.create :allele, :id => 66
      SolrUpdate::Queue::Item.add(allele, 'update')
      assert_not_nil SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(allele.id, 'update')
    end

    should 'add only one command per item, removing any that are already present' do
      setup_for_add_and_process
      SolrUpdate::Queue::Item.add(@allele2_reference, 'delete')

      assert_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(@allele2_reference['id'], 'delete')
    end

    should 'process objects in the order they were added and deletes them' do
      setup_for_add_and_process

      things_processed = []

      SolrUpdate::Queue::Item.process_in_order do |allele_reference, command_type|
        things_processed.push([allele_reference, command_type])
      end

      assert_equal [[@allele1_reference, 'delete'], [@allele2_reference, 'update']], things_processed
      assert_nil SolrUpdate::Queue::Item.find_by_id(@item1.id)
      assert_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
    end

    should 'not delete queue item if an exception is raised during processing' do
      setup_for_add_and_process

      assert_raise(MockError) do
        SolrUpdate::Queue::Item.process_in_order do |allele_ref, command_type|
          raise MockError if allele_ref == @allele2_reference
        end
      end

      assert_nil SolrUpdate::Queue::Item.find_by_id(@item1.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
    end

  end
end
