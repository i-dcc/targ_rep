module SolrUpdate::Observer

  class Allele < ActiveRecord::Observer
    observe ::Allele

    def after_save(allele)
      SolrUpdate::Activator.update_allele_solr_docs(allele)
    end

    def after_destroy(allele)
      SolrUpdate::Activator.delete_allele_solr_docs(allele)
    end

    class << self
      public :new
    end
  end

  class EsCell < ActiveRecord::Observer
    observe ::EsCell

    def after_save(es_cell)
      SolrUpdate::Activator.update_allele_solr_docs(es_cell.allele)
    end

    def after_destroy(es_cell)
      SolrUpdate::Activator.update_allele_solr_docs(es_cell.allele)
    end

    class << self
      public :new
    end
  end

end
