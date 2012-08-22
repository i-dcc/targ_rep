#Bug #8753
#Repair wrong cell strain for all Regeneron Alleles (es cell strain output via biomart)
#
#Added by Vivek Iyer 21 days ago. Updated 6 days ago.
#
#Description
#
#All regeneron alleles currently have parental_cell_line => VGB6
#
#The targrep biomart is reporting an additional field: ES Cell Strain for these alleles:
#es_cell_strain => VGB6,
#
#but this is wrong.
#
#The cell line is VGB6, the cell strain should be C57Bl/6N - I'm not sure where how information is getting into the mart
#(either from a hidden / dependent field in the targrep itself, or from the martbuild process).

COUNT = 16570
DEBUG = false

puts "Environment: #{Rails.env}"
puts "DEBUG" if DEBUG

EsCell.transaction do
  counter = 0
  EsCell.find_each( :batch_size => 500 ) do |cell|
    next if cell.parental_cell_line.blank?
    if cell.parental_cell_line == 'VGB6' && cell.pipeline.name == 'KOMP-Regeneron' && cell.strain = 'VGB6'
      puts "Modifying EsCell id: #{cell.id} - #{cell.name}"
      cell.strain = 'C57BL/6N'
      cell.save
      counter += 1
    end
  end

  raise "Expecting #{COUNT} - found #{counter}" if counter != COUNT

  puts "Count: #{counter}"

  raise "Aborted (debug)" if DEBUG
end

puts "done!"
