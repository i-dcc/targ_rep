class SolrUpdate::SolrCommandFactory

  def self.create_solr_command(allele)
    factory = self.new(allele)
    return factory.create_solr_command
  end

  def create_solr_command
    commands = ActiveSupport::OrderedHash.new

    marker_symbol = gene_index_proxy.get_marker_symbol(allele.mgi_accession_id)
    docs = allele.es_cells.unique_solr_info.map do |es_cell_info|
      {
        'type' => 'allele',
        'id' => allele.id,
        'allele_type' => formatted_allele_type,
        'strain' => es_cell_info['strain'],
        'allele_name' => "#{marker_symbol}<sup>#{es_cell_info['allele_symbol_superscript']}</sup>",

      }
    end

    commands['delete'] = {'query' => "type:allele AND id:#{allele.id}"}
    commands['add'] = docs
    commands['commit'] = {}

    return commands.to_json
  end

  attr_reader :allele, :gene_index_proxy

  def initialize(allele)
    @allele = allele
    @gene_index_proxy = SolrUpdate::IndexProxy::Gene.new
  end

  def formatted_allele_type
    return allele.mutation_subtype.titleize
  end
end
