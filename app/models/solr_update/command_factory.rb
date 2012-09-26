class SolrUpdate::CommandFactory

  module Util
    def formatted_allele_type
      return allele.mutation_subtype.titleize
    end

    def calculate_order_from_info(data)
      if(['EUCOMM', 'EUCOMMTools', 'EUCOMMToolsCre'].include?(data[:pipeline]))
        return {:url => 'http://www.eummcr.org/order.php', :name => 'EUMMCR'}

      elsif(['KOMP-CSD', 'KOMP-Regeneron'].include?(data[:pipeline]))
        if data[:ikmc_project_id].match(/^VG/)
          project = data[:ikmc_project_id]
        else
          project = 'CSD' + data[:ikmc_project_id]
        end
        return {:url => "http://www.komp.org/geneinfo.php?project=#{project}", :name => 'KOMP'}

      elsif(['mirKO', 'Sanger MGP'].include?(data[:pipeline]))
        marker_symbol = gene_index_proxy.get_marker_symbol(allele.mgi_accession_id)
        return {:url => "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for #{marker_symbol}", :name => 'Wtsi'}

      elsif('NorCOMM' == data[:pipeline])
        return {:url => 'http://www.phenogenomics.ca/services/cmmr/escell_services.html', :name => 'NorCOMM'}

      else
        raise "Pipeline not recognized"
      end
    end
  end

  include Util
  include SolrUpdate::Util

  def self.create_solr_command_to_update_in_index(allele_id)
    factory = self.new(allele_id)
    return factory.create_solr_command_to_update_in_index
  end

  def self.create_solr_command_to_delete_from_index(allele_id)
    factory = self.new(allele_id)
    return factory.create_solr_command_to_delete_from_index
  end

  def create_solr_command_to_update_in_index
    commands = ActiveSupport::OrderedHash.new

    marker_symbol = gene_index_proxy.get_marker_symbol(allele.mgi_accession_id)
    docs = allele.es_cells.unique_public_info.map do |es_cell_info|
      order_from_info = calculate_order_from_info(es_cell_info)
      {
        'type' => 'allele',
        'id' => allele.id,
        'product_type' => 'ES Cell',
        'mgi_accession_id' => allele.mgi_accession_id,
        'allele_type' => formatted_allele_type,
        'strain' => es_cell_info[:strain],
        'allele_name' => "#{marker_symbol}<sup>#{es_cell_info[:allele_symbol_superscript]}</sup>",
        'allele_image_url' => allele_image_url(allele.id),
        'genbank_file_url' => genbank_file_url(allele.id),
        'order_from_url' => order_from_info[:url],
        'order_from_name' => order_from_info[:name]
      }
    end

    commands['delete'] = {'query' => "type:allele AND id:#{allele.id}"}
    commands['add'] = docs
    commands['commit'] = {}

    return commands.to_json
  end

  def create_solr_command_to_delete_from_index
    commands = ActiveSupport::OrderedHash.new

    commands['delete'] = {'query' => "type:allele AND id:#{allele_id}"}
    commands['commit'] = {}

    return commands.to_json
  end

  attr_reader :allele_id, :gene_index_proxy

  def initialize(allele_id)
    @allele_id = allele_id
    @gene_index_proxy = SolrUpdate::IndexProxy::Gene.new
  end

  def allele
    @allele ||= ::Allele.find_by_id(allele_id)
  end
end
