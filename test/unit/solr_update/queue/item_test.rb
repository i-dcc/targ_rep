require 'test_helper'

class SolrUpdate::Queue::ItemTest < ActiveSupport::TestCase
  context 'SolrUpdate::Queue::Item' do

    should have_db_column(:created_at).of_type(:datetime)
    should have_db_column(:allele_id).of_type(:integer)

    should '#add object reference and command type to the database in order of being added' do
      allele1 = Factory.build(:allele); allele1.stubs(:id => 57)
      allele2 = Factory.build(:allele); allele2.stubs(:id => 92)
      SolrUpdate::Queue::Item.add(allele1, 'delete')
      SolrUpdate::Queue::Item.add(allele2, 'update')

      item1 = SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(57, 'delete')
      item2 = SolrUpdate::Queue::Item.find_by_allele_id_and_command_type(92, 'update')

      assert_not_nil item1
      assert_not_nil item2
    end

    should 'return entries in #earliest_first order' do
      SolrUpdate::Queue::Item.create!(:allele_id => 2, :command_type => 'update', :created_at => '2012-01-02 00:00:00 UTC')
      SolrUpdate::Queue::Item.create!(:allele_id => 1, :command_type => 'update', :created_at => '2012-01-01 00:00:00 UTC')
      SolrUpdate::Queue::Item.create!(:allele_id => 3, :command_type => 'delete', :created_at => '2012-01-03 00:00:00 UTC')

      commands = SolrUpdate::Queue::Item.earliest_first
      assert_equal [1, 2, 3], commands.map(&:allele_id)
    end

  end
end
