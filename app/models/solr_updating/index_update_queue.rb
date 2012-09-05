class SolrUpdating::IndexUpdateQueue
  def self.add(doc_set)
    SolrUpdating::SolrDocSet.add(doc_set)
  end

  def self.remove_safely(&block)
    solr_doc = SolrUpdating::SolrDocSet.earliest
    block.call(solr_doc)
    solr_doc.destroy
  end
end
