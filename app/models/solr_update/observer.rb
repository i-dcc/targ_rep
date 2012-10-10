module SolrUpdate::Observer

  class Allele < ActiveRecord::Observer
    observe ::Allele

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(allele)
      @enqueuer.allele_updated(allele)
    end

    def after_destroy(allele)
      @enqueuer.allele_destroyed(allele)
    end

    class << self
      public :new
    end
  end

  class EsCell < ActiveRecord::Observer
    observe ::EsCell

    def initialize
      super
      @enqueuer = SolrUpdate::Enqueuer.new
    end

    def after_save(es_cell)
      @enqueuer.es_cell_updated(es_cell)
    end

    def after_destroy(es_cell)
      @enqueuer.es_cell_destroyed(es_cell)
    end

    class << self
      public :new
    end
  end

end
