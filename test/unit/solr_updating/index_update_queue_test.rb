require 'test_helper'

class SolrUpdating::IndexUpdateQueueTest < ActiveSupport::TestCase
  context 'SolrUpdating::IndexUpdateQueue' do

    should 'add new doc sets to beginning of the queue and retrieve them from the end' do
      doc_set_1 = stub('doc_set_1')
      doc_set_2 = stub('doc_set_2')
      seq1 = sequence('seq1')

      SolrUpdating::SolrDocSet.expects(:add).with(doc_set_1).in_sequence(seq1)
      SolrUpdating::SolrDocSet.expects(:add).with(doc_set_2).in_sequence(seq1)

      SolrUpdating::IndexUpdateQueue.add(doc_set_1)
      SolrUpdating::IndexUpdateQueue.add(doc_set_2)

      SolrUpdating::SolrDocSet.expects(:earliest).returns(doc_set_1).in_sequence(seq1)
      doc_set_1.expects(:do_this_before_destroy).in_sequence(seq1)
      doc_set_1.expects(:destroy).with().in_sequence(seq1)

      SolrUpdating::IndexUpdateQueue.remove_safely { |ds| ds.do_this_before_destroy }
    end

    should 'do nothing if remove_safely is called while the queue is empty' do
      flunk 'Peter'
    end

  end
end
