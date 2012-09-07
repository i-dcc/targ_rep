class SolrUpdating::Queue
  def self.add(doc_set)
    SolrUpdating::SolrCommand.add(doc_set)
  end

  def self.remove_safely(&block)
    solr_doc = SolrUpdating::SolrCommand.earliest
    if solr_doc.present?
      block.call(solr_doc)
      solr_doc.destroy
    end
  end

  def self.run
  end
end
