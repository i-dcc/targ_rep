require 'test_helper'

class SolrUpdate::IndexProxyTest < ActiveSupport::TestCase

  context 'SolrUpdate::IndexProxy::Gene' do
    should 'retrieve marker_symbol for an mgi_accession_id from a solr index' do
      index_proxy = SolrUpdate::IndexProxy::Gene.new
      assert_equal 'Cbx1', index_proxy.get_marker_symbol('MGI:105369')
    end
  end

  context 'SolrUpdate::IndexProxy::Allele' do
    should 'send update commands to index and then gets them' do
      docs = [
        {
          'id' => rand(999),
          'type' => 'test'
        },
        {
          'id' => rand(999),
          'type' => 'test'
        }
      ]

      commands = ActiveSupport::OrderedHash.new
      commands['delete'] = {'query' => "type:test"}
      commands['add'] = docs
      commands['commit'] = {}
      commands['optimize'] = {}
      commands_json = commands.to_json

      proxy = SolrUpdate::IndexProxy::Allele.new
      proxy.update(commands_json)

      fetched_docs = proxy.search(:q => 'type:test')
      assert_equal docs.map{|a| a['id']}.sort, fetched_docs.map {|a| a['id']}.sort
    end
  end

end
