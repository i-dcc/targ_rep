class SolrUpdate::CommandFactory
  def self.create_solr_command_to_update_in_index(allele_id)
    allele = Allele.find_by_id(allele_id)
    commands = ActiveSupport::OrderedHash.new
    commands['delete'] = {'query' => "type:allele AND id:#{allele_id}"}
    commands['add'] = SolrUpdate::DocFactory.create_for('allele', allele)
    commands['commit'] = {}

    return commands.to_json
  end

  def self.create_solr_command_to_delete_from_index(allele_id)
    commands = ActiveSupport::OrderedHash.new
    commands['delete'] = {'query' => "type:allele AND id:#{allele_id}"}
    commands['commit'] = {}
    return commands.to_json
  end
end
