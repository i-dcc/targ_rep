require 'test_helper'

class SolrUpdate::QueueTest < ActiveSupport::TestCase
  context 'SolrUpdate::Queue' do

    should 'allow adding of queue items' do
      object1 = stub('object1')
      object2 = stub('object2')
      object3 = stub('object3')

      seq = sequence('seq')

      SolrUpdate::Queue::Item.expects(:add).with(object1, 'update').in_sequence(seq)
      SolrUpdate::Queue::Item.expects(:add).with(object2, 'update').in_sequence(seq)
      SolrUpdate::Queue::Item.expects(:add).with(object3, 'delete').in_sequence(seq)

      SolrUpdate::Queue.enqueue_for_update(object1)
      SolrUpdate::Queue.enqueue_for_update(object2)
      SolrUpdate::Queue.enqueue_for_delete(object3)
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
