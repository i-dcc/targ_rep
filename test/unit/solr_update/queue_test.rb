require 'test_helper'

class SolrUpdate::QueueTest < ActiveSupport::TestCase
  context 'SolrUpdate::Queue' do

    should 'allow adding of queue items' do
      object1_id = 23
      object2_id = 56
      object3_id = 67

      seq = sequence('seq')

      SolrUpdate::Queue::Item.expects(:add).with(object1_id, 'update').in_sequence(seq)
      SolrUpdate::Queue::Item.expects(:add).with(object2_id, 'update').in_sequence(seq)
      SolrUpdate::Queue::Item.expects(:add).with(object3_id, 'delete').in_sequence(seq)

      SolrUpdate::Queue.enqueue_for_update(object1_id)
      SolrUpdate::Queue.enqueue_for_update(object2_id)
      SolrUpdate::Queue.enqueue_for_delete(object3_id)
    end

    should 'be run and process items in order they were added' do
      command1 = stub('command1')
      command2 = stub('command2')

      SolrUpdate::Queue::Item.expects(:process_in_order).with().multiple_yields([4, 'update'], [5, 'delete'])

      SolrUpdate::CommandFactory.expects(:create_solr_command_to_update_in_index).with(4).returns(command1)
      SolrUpdate::CommandFactory.expects(:create_solr_command_to_delete_from_index).with(5).returns(command2)

      SolrUpdate::IndexProxy::Allele.any_instance.expects(:update).with(command1)
      SolrUpdate::IndexProxy::Allele.any_instance.expects(:update).with(command2)

      SolrUpdate::Queue.run
    end

  end
end
