class SolrUpdate::Enqueuer
  def allele_updated(allele)
    SolrUpdate::Queue.enqueue_for_update({'type' => 'allele', 'id' => allele.id})
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
