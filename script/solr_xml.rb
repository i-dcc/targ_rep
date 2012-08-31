
$all_attributes = %w(mgi_allele_id product mutation_subtype strain mgi_allele_name allele_map_url genbank_file_url order_url mutation_type mutation_method name)

# map internal name to schema name

$all_attributes_map = {
  'mgi_allele_id' => 'targ_rep_mgi_allele_id',
  'product' => 'targ_rep_product',
  'mutation_subtype' => 'targ_rep_mutation_subtype',
  'strain' => 'targ_rep_strain',
  'mgi_allele_name' => 'targ_rep_mgi_allele_name',
  'allele_map_url' => 'targ_rep_allele_map_url',
  'genbank_file_url' => 'targ_rep_genbank_file_url',
  'order_url' => 'targ_rep_order_url',
  'mutation_type' => 'targ_rep_mutation_type',
  'mutation_method' => 'targ_rep_mutation_method',
  'name' => 'targ_rep_es_cell_name'
}

$unique_key = $all_attributes_map['mgi_allele_id']
$break_count = 5
$cdata = %w(strain allele_map_url genbank_file_url order_url)
$mgi_allele_ids = %w(MGI:4944295)

def cdata(name, data)
  return '<![CDATA[' + data.to_s + ']]>' if $cdata.include?(name) && data.to_s.length > 0
  return data.to_s
end

def field(name, data)
  "<field name='#{$all_attributes_map[name]}'>" + cdata(name, data) + "</field>"
end

def allele_map_url(id)
  "http://www.knockoutmouse.org/targ_rep/alleles/#{id}/allele-image"
end

def genbank_file_url(id)
  "http://www.knockoutmouse.org/targ_rep/alleles/#{id}/escell-clone-genbank-file"
end

#Order Link:
#If the mouse distribution centre == UCD, and if the IKMC project id looks like 'VG' then
#order visual = 'KOMP'
#order url = http://www.komp.org/geneinfo.php?project=#{project_id}
#
#If the mouse distribution centre == UCD, and if the IKMC project id does NOT look like 'VG' then
#order visual = 'KOMP'
#order url = http://www.komp.org/geneinfo.php?project=CSD#{project_id}
#
#Otherwise, if mi_attempt.distribution_centres has a single centre with "suitable_for_emma = 1 THEN
#order_url = "http://www.emmanet.org/mutant_types.php?keyword=#{result["marker_symbol"]}"
#order_visual = "EMMA"
#
#Otherwise, if mi_attempt.distribution_centres has an entry for WTSI then
#order_url = "mailto:mouseinterest@sanger.ac.uk?Subject=Mutant mouse for #{result["marker_symbol"]}"
#order_visual = "WTSI"

def order_url(cell)
  "http://www.komp.org/geneinfo.php?project=#{cell.ikmc_project_id}"
end

#conditional_ready
#deletion
#targeted_non_conditional

def my_mutation_subtype(cell)
  return "" if ! cell || ! cell.allele || ! cell.allele.mutation_subtype
  return cell.allele.mutation_subtype.to_s.humanize.titleize
end

def build_index
  xml_str = ''
  xml = []
  xml.push '<add>'

  count = 0

  EsCell.find_each( :batch_size => 500 ) do |cell|

    puts "FOUND: '#{cell.mgi_allele_id}'"

    next if ! $mgi_allele_ids.include? cell.mgi_allele_id

    xml.push '<doc>'

    xml.push field('product', 'ES Cell')
    #    xml.push field('mutation_subtype', cell.allele.mutation_subtype)
    xml.push field('mutation_subtype', my_mutation_subtype(cell))
    xml.push field('strain', cell.strain)
    xml.push field('mgi_allele_id', cell.mgi_allele_id)
    xml.push field('allele_map_url', allele_map_url(cell.allele.id))
    xml.push field('genbank_file_url', genbank_file_url(cell.allele.id))
    xml.push field('order_url', order_url(cell))
    xml.push field('mgi_allele_name', 'dunno')
    xml.push field('mutation_type', cell.allele.mutation_type)
    xml.push field('mutation_method', cell.allele.mutation_method)
    xml.push field('name', cell.name)

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

def build_index1
  xml_str = ''
  xml = []
  xml.push '<add>'

  count = 0

  Allele.find_each( :batch_size => 500 ) do |cell|

    xml.push '<doc>'

    xml.push dump_attributes(cell)

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
  string = ''
  model.attributes.each do |attribute|
    string += "<field name='#{attribute[0]}'>#{attribute[1]}</field>\n"
  end
  string[0..-2]
end

def create_schema_xml
  replacement_text = []
  $all_attributes.each do |attribute|
    replacement_text.push("<field name='#{$all_attributes_map[attribute]}' type='text' indexed='true' stored='true' />")
  end

  replacement_text = replacement_text.join "\n"

  replacement_text2 = []
  $all_attributes.each do |attribute|
    replacement_text2.push("<copyField source='#{$all_attributes_map[attribute]}' dest='text' />")
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
