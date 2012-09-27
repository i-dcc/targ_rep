module SolrUpdate::Observer

  class Allele < ActiveRecord::Observer
    observe ::Allele

    def after_save(allele)
      SolrUpdate::Queue.enqueue_for_update(allele)
    end

    def after_destroy(allele)
      SolrUpdate::Queue.enqueue_for_delete(allele)
    end

    class << self
      public :new
    end
  end

  class EsCell < ActiveRecord::Observer
    observe ::EsCell

    def after_save(es_cell)
      SolrUpdate::Queue.enqueue_for_update(es_cell.allele)
    end

    def after_destroy(es_cell)
      SolrUpdate::Queue.enqueue_for_update(es_cell.allele)
    end

    class << self
      public :new
    end
  end

end
