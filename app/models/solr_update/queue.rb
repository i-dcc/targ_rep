class SolrUpdate::Queue
  def self.add(command)
    SolrUpdate::SolrCommand.add(command)
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
