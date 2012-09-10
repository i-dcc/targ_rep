class SolrUpdate::Observer
  def after_save(allele)
    doc_set = SolrUpdate::SolrDocSetFactory.create_solr_doc_set(allele)
    SolrUpdate::IndexUpdateQueue.add(doc_set)
  end
end
