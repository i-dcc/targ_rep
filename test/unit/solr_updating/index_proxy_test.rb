require 'test_helper'

class SolrUpdate::IndexProxyTest < ActiveSupport::TestCase
  context 'SolrUpdate::IndexProxy' do

    should 'retrieve marker_symbol for an mgi_accession_id from a solr index' do
      index_proxy = SolrUpdate::IndexProxy::Gene.new
      assert_equal 'Cbx1', index_proxy.get_marker_symbol('MGI:105369')
    end

  end
end
