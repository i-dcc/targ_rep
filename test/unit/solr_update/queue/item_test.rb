require 'test_helper'

class SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase

  def setup_for_add_and_process
    @allele1_reference = {'type' => 'allele', 'id' => 57}
    @allele2_reference = {'type' => 'allele', 'id' => 92}
    SolrUpdate::Queue::Item.add(@allele1_reference, 'delete')
    SolrUpdate::Queue::Item.add(@allele2_reference, 'update')

    @item1 = SolrUpdate::Queue::Item.find_by_allele_id_and_action(@allele1_reference['id'], 'delete')
    @item2 = SolrUpdate::Queue::Item.find_by_allele_id_and_action(@allele2_reference['id'], 'update')
  end

  context 'SolrUpdate::Queue::Item' do

    should have_db_column(:created_at).of_type(:datetime)
    should have_db_column(:allele_id).of_type(:integer)
    should have_db_column(:action)

    should belong_to(:allele)

    should 'return entries in #earliest_first order' do
      SolrUpdate::Queue::Item.create!(:allele_id => 2, :action => 'update', :created_at => '2012-01-02 00:00:00 UTC')
      SolrUpdate::Queue::Item.create!(:allele_id => 1, :action => 'update', :created_at => '2012-01-01 00:00:00 UTC')
      SolrUpdate::Queue::Item.create!(:allele_id => 3, :action => 'delete', :created_at => '2012-01-03 00:00:00 UTC')

      commands = SolrUpdate::Queue::Item.earliest_first
      assert_equal [1, 2, 3], commands.map(&:allele_id)
    end

    should 'have #reference' do
      i = SolrUpdate::Queue::Item.new(:allele_id => 4, :action => 'update')
      assert_equal({'type' => 'allele', 'id' => 4}, i.reference)
    end

    should '#add object reference and command type to the database in order of being added' do
      setup_for_add_and_process

      assert_not_nil @item1
      assert_not_nil @item2
    end

    should 'add model object directly instead of it\'s id' do
      allele = Factory.create :allele, :id => 66
      SolrUpdate::Queue::Item.add(allele, 'update')
      assert_not_nil SolrUpdate::Queue::Item.find_by_allele_id_and_action(allele.id, 'update')
    end

    should 'add only one command per item, removing any that are already present' do
      setup_for_add_and_process
      SolrUpdate::Queue::Item.add(@allele2_reference, 'delete')

      assert_nil SolrUpdate::Queue::Item.find_by_id(@item2.id)
      assert_not_nil SolrUpdate::Queue::Item.find_by_allele_id_and_action(@allele2_reference['id'], 'delete')
    end

    should 'process objects in the order they were added' do
      setup_for_add_and_process

      things_processed = []

      SolrUpdate::Queue::Item.process_in_order do |item|
        things_processed.push(item)
      end

      assert_equal [@item1, @item2], things_processed
    end

    should 'only process a limited number of items per call if told to' do
      (1..10).each do |i|
        SolrUpdate::Queue::Item.create!(:action => 'update', :allele_id => i)
      end

      ids_processed = []

      SolrUpdate::Queue::Item.process_in_order(:limit => 3) do |item|
        ids_processed.push item.id
        item.destroy
      end

      assert_equal 3, ids_processed.size

      SolrUpdate::Queue::Item.process_in_order(:limit => 2) do |item|
        ids_processed.push item.id
        item.destroy
      end

      assert_equal 5, ids_processed.size

      SolrUpdate::Queue::Item.process_in_order do |item|
        ids_processed.push item.id
        item.destroy
      end

      assert_equal 10, ids_processed.size
    end

  end
end
