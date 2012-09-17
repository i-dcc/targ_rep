class SolrUpdate::Activator
  def self.update_allele_solr_docs(allele)
    allele = ::Allele.find(allele)
    command = SolrUpdate::SolrCommandFactory.create_solr_command_to_update_in_index(allele)
    SolrUpdate::Queue.add(command)
  end

  def self.delete_allele_solr_docs(allele)
    command = SolrUpdate::SolrCommandFactory.create_solr_command_to_delete_from_index(allele)
    SolrUpdate::Queue.add(command)
  end

end
