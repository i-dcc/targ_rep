require 'test_helper'

class SolrUpdate::QueueTest < ActiveSupport::TestCase
  context 'SolrUpdate::Queue' do

    should 'add new doc sets to beginning of the queue and retrieve them from the end' do
      solr_command_1 = stub('solr_command_1')
      solr_command_2 = stub('solr_command_2')
      seq1 = sequence('seq1')

      SolrUpdate::SolrCommand.expects(:add).with(solr_command_1).in_sequence(seq1)
      SolrUpdate::SolrCommand.expects(:add).with(solr_command_2).in_sequence(seq1)

      SolrUpdate::SolrCommand.expects(:earliest).returns(solr_command_1).in_sequence(seq1)
      solr_command_1.expects(:do_this_before_destroy).in_sequence(seq1)
      solr_command_1.expects(:destroy).with().in_sequence(seq1)

      SolrUpdate::Queue.add(solr_command_1)
      SolrUpdate::Queue.add(solr_command_2)
      SolrUpdate::Queue.remove_safely { |ds| ds.do_this_before_destroy }
    end

    should 'do nothing if remove_safely is called while the queue is empty' do
      SolrUpdate::SolrCommand.expects(:earliest).returns(nil)

      SolrUpdate::Queue.remove_safely {flunk 'I should never get here'}
    end

  end
end
