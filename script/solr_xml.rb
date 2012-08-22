
require 'pp'

xml_str = ''
xml = []
xml.push '<add>'

es_cell_attributes = %w(allele_id name allele_symbol_superscript ikmc_project_id mgi_allele_id parental_cell_line strain)

count = 0

EsCell.find_each( :batch_size => 500 ) do |cell|

  xml.push '<doc>'

  #  xml.push "<field name='name'>#{cell.name}</field>"

  #cell.attributes.each do |attribute|
  #  xml.push "<field name='#{attribute[0]}'>#{attribute[1]}</field>"
  #  pp attribute
  #end

  es_cell_attributes.each do |attribute|
    attribute_name = attribute == 'name' ? 'es_cell_name' : attribute
    xml.push "<field name='#{attribute_name}'><![CDATA[#{cell.send(attribute)}]]></field>" if attribute_name == 'allele_symbol_superscript' || attribute_name == 'strain'
    xml.push "<field name='#{attribute_name}'>#{cell.send(attribute)}</field>" if attribute_name != 'allele_symbol_superscript' && attribute_name != 'strain'
  end

  xml.push "<field name='mutation_subtype'>#{cell.allele.mutation_subtype}</field>"

  xml.push '</doc>'

  count += 1

  break if count > 100
end

xml.push '</add>'

xml_str += xml.join("\n")

puts File.dirname(__FILE__)
puts Dir.pwd + '/targ_rep.xml'

target_file = File.dirname(__FILE__) + '/targ_rep.xml'

File.open(target_file, 'w') {|f| f.write(xml_str) }

puts "done!"
