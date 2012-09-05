require 'test_helper'

class SolrUpdating::ObserverTest < ActiveSupport::TestCase
  context 'SolrUpdating::Observer' do

    should 'observe Allele object updates and queue an index update' do
      doc_set = stub('doc_set')
      allele = stub('allele')
      SolrUpdating::SolrDocSetFactory.expects(:create_solr_doc_set).with(allele).returns(doc_set)
      SolrUpdating::IndexUpdateQueue.expects(:add).with(doc_set)

      o = SolrUpdating::Observer.new
      o.after_save allele
    end

  end
end
