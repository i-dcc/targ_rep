require 'test_helper'

class SolrUpdate::SolrCommandTest < ActiveSupport::TestCase
  context 'SolrUpdate::SolrCommand' do

    should have_db_column(:data).with_options(:null => false)

  end
end
