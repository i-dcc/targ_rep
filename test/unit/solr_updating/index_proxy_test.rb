require 'test_helper'

class SolrUpdating::IndexProxyTest < ActiveSupport::TestCase
  context 'SolrUpdating::IndexProxy' do

    should 'retrieve marker_symbol for an mgi_accession_id from a solr index' do
      index_proxy = SolrUpdating::IndexProxy::Gene.new
      assert_equal 'Cbx1', index_proxy.get_marker_symbol('MGI:105369')
    end

  end
end
