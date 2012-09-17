class SolrUpdate::Activator
  def self.update_allele_solr_docs(allele)
    allele.reload
    command = SolrUpdate::SolrCommandFactory.create_solr_command(allele)
    SolrUpdate::Queue.add(command)
  end

end
