require 'test_helper'

class SolrUpdate::QueueTest < ActiveSupport::TestCase
  context 'SolrUpdate::Queue' do

    should 'add new doc sets to beginning of the queue and runs them in the same order' do
      solr_command_1 = stub('solr_command_1', :data => 'data_1')
      solr_command_2 = stub('solr_command_2', :data => 'data_2')
      seq1 = sequence('seq1')

      SolrUpdate::SolrCommand.expects(:add).with(solr_command_1).in_sequence(seq1)
      SolrUpdate::SolrCommand.expects(:add).with(solr_command_2).in_sequence(seq1)

      SolrUpdate::SolrCommand.expects(:earliest_first).returns([solr_command_1, solr_command_2]).in_sequence(seq1)

      SolrUpdate::IndexProxy::Allele.any_instance.expects(:update).with('data_1').in_sequence(seq1)
      solr_command_1.expects(:destroy).in_sequence(seq1)

      SolrUpdate::IndexProxy::Allele.any_instance.expects(:update).with('data_2').in_sequence(seq1)
      solr_command_2.expects(:destroy).in_sequence(seq1)


      SolrUpdate::Queue.add(solr_command_1)
      SolrUpdate::Queue.add(solr_command_2)
      SolrUpdate::Queue.run
    end

  end
end
