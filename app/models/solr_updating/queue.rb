class SolrUpdate::Queue
  def self.add(doc_set)
    SolrUpdate::SolrCommand.add(doc_set)
  end

  def self.remove_safely(&block)
    solr_doc = SolrUpdate::SolrCommand.earliest
    if solr_doc.present?
      block.call(solr_doc)
      solr_doc.destroy
    end
  end

  def self.run
  end
end
