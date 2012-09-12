require 'test_helper'

class SolrUpdate::SolrCommandTest < ActiveSupport::TestCase
  context 'SolrUpdate::SolrCommand' do

    should have_db_column(:data).with_options(:null => false)

    should 'return commands in earliest first order with #earliest_first' do
      SolrUpdate::SolrCommand.create!(:data => 'data2', :created_at => '2012-01-02 00:00:00 UTC')
      SolrUpdate::SolrCommand.create!(:data => 'data1', :created_at => '2012-01-01 00:00:00 UTC')
      SolrUpdate::SolrCommand.create!(:data => 'data3', :created_at => '2012-01-03 00:00:00 UTC')

      data_values = SolrUpdate::SolrCommand.earliest_first
      assert_equal ['data1', 'data2', 'data3'], data_values
    end

    should 'add commands with a very recent timestamp' do
      SolrUpdate::SolrCommand.add('test data 1')
      SolrUpdate::SolrCommand.first.update_attributes!(:created_at => 1.minute.ago)
      SolrUpdate::SolrCommand.add('test data 2')

      commands = [
        SolrUpdate::SolrCommand.find_by_data('test data 1'),
        SolrUpdate::SolrCommand.find_by_data('test data 2')
      ]
      assert_operator commands[0].created_at, :<, commands[1].created_at
    end

  end
end
