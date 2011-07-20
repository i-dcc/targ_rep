# Get all es_cells and set the strain...

EsCell.find_each( :batch_size => 100 ) do |cell|
  unless cell.parental_cell_line.blank?
    cell.strain = case cell.parental_cell_line
    when /JM8/ then 'C57BL/6N'
    when /C2/  then 'C57BL/6N'
    when /AB2/ then '129S7'
    when /SI2/ then '129S7'
    when '[Enter your data value]'
      cell.parental_cell_line = nil
      nil
    else
      puts "unknown cell_line: #{cell.parental_cell_line}"
    end
    cell.save
  end
end

