require 'test_helper'

class SolrUpdate::QueueTest < ActiveSupport::TestCase
  context 'SolrUpdate::Queue' do

    should 'allow adding of queue items' do
      allele1 = Factory.build(:allele).stubs(:id => 1)
      allele2 = Factory.build(:allele).stubs(:id => 2)
      allele3 = Factory.build(:allele).stubs(:id => 3)

      seq = sequence('seq')

      SolrUpdate::Queue::Item.expects(:add).with(allele1, 'update').in_sequence(seq)
      SolrUpdate::Queue::Item.expects(:add).with(allele2, 'update').in_sequence(seq)
      SolrUpdate::Queue::Item.expects(:add).with(allele3, 'delete').in_sequence(seq)

      SolrUpdate::Queue.enqueue_for_update(allele1)
      SolrUpdate::Queue.enqueue_for_update(allele2)
      SolrUpdate::Queue.enqueue_for_delete(allele3)
    end

  end
end
