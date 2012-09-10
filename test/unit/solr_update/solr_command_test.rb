require 'test_helper'

class SolrUpdate::SolrCommandTest < ActiveSupport::TestCase
  context 'SolrUpdate::SolrCommand' do

    should have_db_column(:data).with_options(:null => false)

    should 'return commands in earliest first order with #earliest_first' do
      SolrUpdate::SolrCommand.create!(:data => 'data2', :created_at => '2012-01-02 00:00:00 UTC')
      SolrUpdate::SolrCommand.create!(:data => 'data1', :created_at => '2012-01-01 00:00:00 UTC')
      SolrUpdate::SolrCommand.create!(:data => 'data3', :created_at => '2012-01-03 00:00:00 UTC')

      data_values = SolrUpdate::SolrCommand.earliest_first.map(&:data)
      assert_equal ['data1', 'data2', 'data3'], data_values
    end

  end
end
