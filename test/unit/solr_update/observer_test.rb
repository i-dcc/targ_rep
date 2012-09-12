require 'test_helper'

class SolrUpdate::ObserverTest < ActiveSupport::TestCase
  context 'SolrUpdate::Observer' do

    should 'observe Allele object updates and queue an index update' do
      command = stub('doc_set')
      allele = stub('allele')
      SolrUpdate::SolrCommandFactory.expects(:create_solr_command).with(allele).returns(command)
      SolrUpdate::Queue.expects(:add).with(command)

      o = SolrUpdate::Observer.new
      o.after_save allele
    end

  end
end
