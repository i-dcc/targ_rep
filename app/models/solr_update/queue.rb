class SolrUpdate::Queue
  def self.enqueue_for_update(object_id)
    SolrUpdate::Queue::Item.add(object_id, 'update')
  end

  def self.enqueue_for_delete(object_id)
    SolrUpdate::Queue::Item.add(object_id, 'delete')
  end

  def self.run
    proxy = SolrUpdate::IndexProxy::Allele.new
    SolrUpdate::Queue::Item.process_in_order do |object_id, command_type|
      if command_type == 'update'
        command = SolrUpdate::CommandFactory.create_solr_command_to_update_in_index(object_id)
      elsif command_type == 'delete'
        command = SolrUpdate::CommandFactory.create_solr_command_to_delete_from_index(object_id)
      end
      proxy.update(command)
    end
  end

end
