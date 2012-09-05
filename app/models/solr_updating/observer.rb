class SolrUpdating::Observer
  def after_save(allele)
    doc_set = SolrUpdating::SolrDocSetFactory.create_solr_doc_set(allele)
    SolrUpdating::IndexUpdateQueue.add(doc_set)
  end
end
