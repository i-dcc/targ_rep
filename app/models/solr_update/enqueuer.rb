class SolrUpdate::Enqueuer
  def allele_updated(allele)
    gene_proxy = SolrUpdate::IndexProxy::Gene.new

    begin
      gene_proxy.get_marker_symbol
      SolrUpdate::Queue.enqueue_for_update({'type' => 'allele', 'id' => allele.id})
    rescue SolrUpdate::IndexProxy::LookupError
      SolrUpdate::Queue.enqueue_for_delete({'type' => 'allele', 'id' => allele.id})
    end
  end

  def allele_destroyed(allele)
    SolrUpdate::Queue.enqueue_for_delete({'type' => 'allele', 'id' => allele.id})
  end

  def es_cell_updated(es_cell)
    allele_updated(es_cell.allele)
  end

  def es_cell_destroyed(es_cell)
    allele_updated(es_cell.allele)
  end
end
