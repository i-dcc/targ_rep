class SolrUpdate::DocFactory

  extend SolrUpdate::Util

  def self.gene_index_proxy
    @@gene_index_proxy ||= SolrUpdate::IndexProxy::Gene.new
  end

  def self.create(reference)
    raise unless reference['type'] == 'allele'
    return create_for_allele(Allele.find(reference['id']))
  end

  def self.create_for_allele(allele)
    marker_symbol = gene_index_proxy.get_marker_symbol(allele.mgi_accession_id)
    docs = allele.es_cells.unique_public_info.map do |es_cell_info|
      order_from_info = calculate_order_from_info(es_cell_info.merge(:allele => allele))
      {
        'type' => 'allele',
        'id' => allele.id,
        'product_type' => 'ES Cell',
        'mgi_accession_id' => allele.mgi_accession_id,
        'allele_type' => allele.mutation_subtype.titleize,
        'strain' => es_cell_info[:strain],
        'allele_name' => "#{marker_symbol}<sup>#{es_cell_info[:allele_symbol_superscript]}</sup>",
        'allele_image_url' => allele_image_url(allele.id),
        'genbank_file_url' => genbank_file_url(allele.id),
        'order_from_url' => order_from_info[:url],
        'order_from_name' => order_from_info[:name]
      }
    end

    return docs
  end

  def self.calculate_order_from_info(data)
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
      marker_symbol = gene_index_proxy.get_marker_symbol(data[:allele].mgi_accession_id)
      return {:url => "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant ES Cell line for #{marker_symbol}", :name => 'Wtsi'}

    elsif('NorCOMM' == data[:pipeline])
      return {:url => 'http://www.phenogenomics.ca/services/cmmr/escell_services.html', :name => 'NorCOMM'}

    else
      raise "Pipeline not recognized"
    end
  end
end
