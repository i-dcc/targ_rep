class SolrUpdate::Queue
  def self.add(doc_set)
    SolrUpdate::SolrCommand.add(doc_set)
  end

  def self.run
    proxy = SolrUpdate::IndexProxy::Allele.new
    commands = SolrUpdate::SolrCommand.earliest_first
    commands.each do |command|
      SolrUpdate::SolrCommand.transaction do
        proxy.send_update(command)
        command.destroy
      end
    end
  end
end
