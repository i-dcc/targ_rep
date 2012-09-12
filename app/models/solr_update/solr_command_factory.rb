class SolrUpdate::SolrCommandFactory
  def self.create_solr_command(allele)
    commands = ActiveSupport::OrderedHash.new

    commands['delete'] = {'query' => "type:allele AND id:#{allele.id}"}
    commands['add'] = ''
    commands['commit'] = ''

    return commands.to_json
  end
end
