require 'test_helper'

class SolrUpdate::IndexProxyTest < ActiveSupport::TestCase

  context 'SolrUpdate::IndexProxy::Base' do
    context '#should_use_proxy_for?' do
      should 'work' do
        begin
          old_no_proxy = ENV['NO_PROXY']
          ENV['NO_PROXY'] = 'somedomain, fakedomain, nonexistent_domain'
          assert_equal true, SolrUpdate::IndexProxy::Base.should_use_proxy_for?('testdomain.com')
          assert_equal false, SolrUpdate::IndexProxy::Base.should_use_proxy_for?('fakedomain.com')
        ensure
          ENV['NO_PROXY'] = old_no_proxy if old_no_proxy
        end
      end
    end
  end

  context 'SolrUpdate::IndexProxy::Gene' do
    should 'retrieve marker_symbol for an mgi_accession_id from a solr index' do
      index_proxy = SolrUpdate::IndexProxy::Gene.new
      assert_equal 'Cbx1', index_proxy.get_marker_symbol('MGI:105369')
      assert_equal 'Tead1', index_proxy.get_marker_symbol('MGI:101876')
    end

    should 'raise error if gene not found' do
      index_proxy = SolrUpdate::IndexProxy::Gene.new
      assert_raise(SolrUpdate::IndexProxy::LookupError) { index_proxy.get_marker_symbol('MGI:XXXXXXXXXXXXX') }
    end
  end

  context 'SolrUpdate::IndexProxy::Allele' do
    should 'send update commands to index and then gets them: #search and #update' do
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
