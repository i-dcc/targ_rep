class SolrUpdate::CommandFactory
  def self.create_solr_command_to_update_in_index(reference)
    return create_solr_command(reference, true)
  end

  def self.create_solr_command_to_delete_from_index(reference)
    return create_solr_command(reference, false)
  end

  def self.create_solr_command(reference, should_add)
    commands = ActiveSupport::OrderedHash.new
    commands['delete'] = {'query' => "type:#{reference['type']} AND id:#{reference['id']}"}
    commands['add'] = SolrUpdate::DocFactory.create(reference) if should_add == true
    commands['commit'] = {}

    return commands.to_json
  end
end
