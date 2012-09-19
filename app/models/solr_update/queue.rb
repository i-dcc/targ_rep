class SolrUpdate::Queue
  def self.enqueue_for_update(object)
    SolrUpdate::Queue::Item.add(object, 'update')
  end

  def self.enqueue_for_delete(object)
    SolrUpdate::Queue::Item.add(object, 'delete')
  end
end
