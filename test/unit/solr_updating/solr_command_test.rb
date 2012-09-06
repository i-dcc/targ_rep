require 'test_helper'

class SolrUpdating::SolrCommandTest < ActiveSupport::TestCase
  context 'SolrUpdating::SolrCommand' do

    should have_db_column(:data).with_options(:null => false)

  end
end
