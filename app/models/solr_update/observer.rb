class SolrUpdate::Observer < ActiveRecord::Observer
  observe Allele

  def after_save(allele)
    command = SolrUpdate::SolrCommandFactory.create_solr_command(allele)
    SolrUpdate::Queue.add(command)
  end

  class << self
    public :new
  end
end
