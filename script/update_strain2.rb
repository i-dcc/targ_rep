# Get all es_cells and set the strain...

COUNT = 14490
DEBUG = true

puts "Environment: #{Rails.env}"

EsCell.transaction do
  counter = 0
  EsCell.find_each( :batch_size => 500 ) do |cell|
    next if cell.parental_cell_line.blank?
    if cell.parental_cell_line == 'VGB6' && cell.pipeline.name == 'KOMP-Regeneron' && cell.strain = 'VGB6'
      puts "Modifying EsCell id #{cell.id}"
      cell.strain = 'C57Bl/6N'
      cell.save
      counter += 1
    end
  end

  raise "Expecting #{COUNT} - found #{counter}" if counter != COUNT

  puts "Count: #{counter}"

  raise "Aborted (debug)" if DEBUG
end

puts "done!"
