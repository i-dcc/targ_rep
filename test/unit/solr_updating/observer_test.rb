require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase
  context 'SolrUpdate::Observer' do

    should 'observe Allele object updates and queue an index update' do
      doc_set = stub('doc_set')
      allele = stub('allele')
      SolrUpdate::SolrDocSetFactory.expects(:create_solr_doc_set).with(allele).returns(doc_set)
      SolrUpdate::Queue.expects(:add).with(doc_set)

      o = SolrUpdate::Observer.new
      o.after_save allele
    end

  end
end
