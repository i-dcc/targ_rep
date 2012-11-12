#!/usr/bin/env ruby

gene = SolrUpdate::IndexProxy::Gene.new

gene_name_lookup = {}

gene.search(:q => '*:*', :rows => 1000000).each do |d|
  gene_name_lookup[d['mgi_accession_id']] = d['marker_symbol']
end

puts "NOTICE: Genes: #{gene_name_lookup.keys.size}"

bad_alleles = Allele.all.find_all {|a| gene_name_lookup[a.mgi_accession_id].blank? }

puts "NOTICE: Bad alleles: #{bad_alleles.size}"

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

old_to_new_mgi_id_mapping = ActiveSupport::OrderedHash.new
biomart_results.each do |result|
  old_to_new_mgi_id_mapping[result['secondary_mgi_accession_id'].to_s] = result['mgi_accession_id'].to_s
end

alleles_without_new_mgi_id = []

Allele.transaction do
  bad_alleles.each do |allele|
    old_mgi_id = allele.mgi_accession_id
    new_mgi_id = old_to_new_mgi_id_mapping[allele.mgi_accession_id]
    if new_mgi_id.blank?
      alleles_without_new_mgi_id << allele
    else
      allele.mgi_accession_id = new_mgi_id
      if ! allele.save
        if allele.errors[:project_design_id].include? 'must have unique design features'
          puts "NOTICE: Deleting Allele #{allele.id}(#{old_mgi_id}) since another one already exists with same design features with updated MGI ID of #{new_mgi_id}"
          allele.destroy
        else
          puts "CRITICAL: Validation failed for Allele #{allele.id}: #{allele.errors.full_messages}"
        end
      else
        puts "NOTICE: Changing MGI id of Allele #{allele.id} from #{allele.mgi_accession_id} to #{new_mgi_id}"
      end

    end
  end

  alleles_without_new_mgi_id.each do |allele|
    puts "CRITICAL: No new MGI id found for #{allele.mgi_accession_id} (Allele #{allele.id})"
  end

  puts "NOTICE: old -> new MGI id mappings written to file tmp/old_to_new_mgi_accession_id_mapping.#{Rails.env}.yaml"

  File.open("tmp/old_to_new_mgi_accession_id_mapping.#{Rails.env}.yaml", 'wb') do |file|
    file.puts old_to_new_mgi_id_mapping.to_yaml
  end

  raise 'ROLLBACK'
end
