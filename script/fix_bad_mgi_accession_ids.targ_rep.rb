#!/usr/bin/env ruby

gene = SolrUpdate::IndexProxy::Gene.new

gene_name_lookup = {}

gene.search(:q => '*:*', :rows => 1000000).each do |d|
  gene_name_lookup[d['mgi_accession_id']] = d['marker_symbol']
end

puts "Genes: #{gene_name_lookup.keys.size}"

bad_alleles = Allele.all.find_all {|a| gene_name_lookup[a.mgi_accession_id].blank? }

puts "Bad alleles: #{bad_alleles.size}"

DCC_BIOMART = Biomart::Dataset.new(
  'http://www.i-dcc.org/biomart',
  { :name => 'dcc' }
)

biomart_results = DCC_BIOMART.search(
  :process_results => true,
  :filters => { 'secondary_mgi_accession_id' => bad_alleles.map(&:mgi_accession_id) },
  :attributes => ['mgi_accession_id', 'secondary_mgi_accession_id'],
  :required_attributes => ['mgi_accession_id', 'secondary_mgi_accession_id']
)

old_to_new_mgi_id_mapping = {}
biomart_results.each do |result|
  old_to_new_mgi_id_mapping[result['secondary_mgi_accession_id']] = result['mgi_accession_id']
end

alleles_without_new_mgi_id = []

Allele.transaction do
  bad_alleles.each do |allele|
    new_mgi_id = old_to_new_mgi_id_mapping[allele.mgi_accession_id]
    if new_mgi_id.blank?
      alleles_without_new_mgi_id << allele
    else
      puts "Changing MGI id of Allele #{allele.id} from #{allele.mgi_accession_id} to #{new_mgi_id}"
      allele.mgi_accession_id = new_mgi_id
      if ! allele.save
        puts "CRITICAL: Validation failed for Allele #{allele.id}: #{allele.errors.full_messages}"
      end
    end
  end

  alleles_without_new_mgi_id.each do |allele|
    puts "CRITICAL: No new MGI id found for #{allele.mgi_accession_id} (Allele #{allele.id})"
  end

  puts "old -> new MGI id mappings written to file tmp/old_to_new_mgi_accession_id_mapping.#{Rails.env}.yaml"

  File.open("tmp/old_to_new_mgi_accession_id_mapping.#{Rails.env}.yaml", 'wb') do |file|
    file.puts old_to_new_mgi_id_mapping.to_yaml
  end

  raise 'ROLLBACK'
end
