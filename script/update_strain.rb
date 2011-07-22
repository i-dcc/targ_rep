# Get all es_cells and set the strain...

EsCell.find_each( :batch_size => 500 ) do |cell|
  next if cell.parental_cell_line.blank?
  if cell.parental_cell_line =~ /JM8A/ or cell.parental_cell_line =~ /JM8\.A/
    cell.strain = 'C57BL/6N-A<tm1Brd>/a'
    cell.save
  end

#  unless cell.parental_cell_line.blank?
#    cell.strain = case cell.parental_cell_line
#    when /JM8A/   then 'C57BL/6N-A<tm1Brd>/a'
#    when /JM8\.A/ then 'C57BL/6N-A<tm1Brd>/a'
#    when /JM8/    then 'C57BL/6N'
#    when /C2/     then 'C57BL/6N'
#    when /AB2/    then '129S7'
#    when /SI/     then '129S7'
#    when '[Enter your data value]'
#      cell.parental_cell_line = nil
#      nil
#    else
#      puts "unknown cell_line: #{cell.parental_cell_line}"
#    end
#    cell.save
#  end
end

