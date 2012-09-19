class SolrUpdate::Queue
  def self.enqueue_for_update(object)
    SolrUpdate::Queue::Item.add(object, 'update')
  end

  def self.enqueue_for_delete(object)
    SolrUpdate::Queue::Item.add(object, 'delete')
  end

  def self.run
    p = SolrUpdate::IndexProxy::Allele.new
    SolrUpdate::Queue::Item.process_in_order do |object, command_type|
      if command_type == 'update'
        command = SolrUpdate::CommandFactory.create_solr_command_to_update_in_index(object)
      elsif command_type == 'delete'
        command = SolrUpdate::CommandFactory.create_solr_command_to_delete_from_index(object)
      end
      p.update(command)
    end
  end

end
