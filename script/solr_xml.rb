
$es_cell_attributes = %w(allele_id name allele_symbol_superscript ikmc_project_id mgi_allele_id parental_cell_line strain)
$cdata_attributes = %w(allele_symbol_superscript strain)
$all_attributes = $es_cell_attributes + $cdata_attributes
$unique_key = 'mgi_allele_id'
$break_count = -1

def build_index
  xml_str = ''
  xml = []
  xml.push '<add>'

  count = 0

  EsCell.find_each( :batch_size => 500 ) do |cell|

    xml.push '<doc>'

    $es_cell_attributes.each do |attribute|
      attribute_name = attribute == 'name' ? 'es_cell_name' : attribute
      xml.push "<field name='#{attribute_name}'><![CDATA[#{cell.send(attribute)}]]></field>" if $cdata_attributes.include? attribute_name
      xml.push "<field name='#{attribute_name}'>#{cell.send(attribute)}</field>" if ! $cdata_attributes.include? attribute_name
    end

    xml.push "<field name='mutation_subtype'>#{cell.allele.mutation_subtype}</field>"

    xml.push '</doc>'

    count += 1

    break if $break_count > -1 && count >= $break_count
  end

  xml.push '</add>'

  xml_str += xml.join("\n")

  puts File.dirname(__FILE__)
  puts Dir.pwd + '/targ_rep.xml'

  target_file = File.dirname(__FILE__) + '/targ_rep.xml'

  File.open(target_file, 'w') {|f| f.write(xml_str) }

  puts "done!"
end

def dump_attributes(model)
  model.attributes.each do |attribute|
    xml.push "<field name='#{attribute[0]}'>#{attribute[1]}</field>"
  end
end

def create_schema_xml
  replacement_text = []
  $all_attributes.each do |attribute|
    replacement_text.push("<field name='#{attribute}' type='text' indexed='true' stored='true' />")
  end

  replacement_text = replacement_text.join "\n"

  replacement_text2 = []
  $all_attributes.each do |attribute|
    replacement_text2.push("<copyField source='#{attribute}' dest='text' />")
  end

  replacement_text2 = replacement_text2.join "\n"

  text = IO.read(File.dirname(__FILE__) + '/schema.xml')

  text = text.sub(/\<\!\-\-TARG_REP_FIELD_START\-\-\>(.+?)\<\!\-\-TARG_REP_FIELD_END\-\-\>/m, '<!--TARG_REP_FIELD_START-->' + "\n#{replacement_text}\n" + '<!--TARG_REP_FIELD_END-->')

  text = text.sub(/\<\!\-\-TARG_REP_COPYFIELD_BEGIN\-\-\>(.+?)\<\!\-\-TARG_REP_COPYFIELD_END\-\-\>/m, '<!--TARG_REP_COPYFIELD_BEGIN-->' + "\n#{replacement_text2}\n" + '<!--TARG_REP_COPYFIELD_END-->')

  text = text.sub(/\<uniqueKey\>(.+?)\<\/uniqueKey\>/m, '<uniqueKey>' + "#{$unique_key}" + '</uniqueKey>')

  IO.write(File.dirname(__FILE__) + '/schema.xml', text)
end

################################################################################

create_schema_xml

build_index