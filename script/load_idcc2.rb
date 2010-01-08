#!/usr/bin/env ruby -wKU

# Authors::    Darren Oakley  (mailto:do2@sanger.ac.uk),
#              Sebastien Briois (mailto:sb25@sanger.ac.uk)
#
# == Synopsis
#
# This script aims to load IDCC database with data retrieved from 
# HTGT database
# It will use IDCC webservices to load the data.
#
# /!\ This script does not delete IDCC alleles if they do not exist in HTGT
# 
# Algo steps :
# ------------
#
# 1- Retrieve designs: 
#      * get all features associated with design_id
#      * Design object contains design details and a hash of features:
#          design.design_type = "Knock Out"
#          design.features = {
#            :feature_name => {
#              :start => feature start position
#              :end   => feature end position
#            }
#          }
#
# 2- Validates designs. Following designs are considered as invalid:
#      * designs with missing features
#      * designs with features missing start or end positions
#      * designs with multiple start or end positions for the same feature
#
# 3- Create or update alleles retrieved from valid designs. Because a full
#    update would take ages to run, the idea is to retrieve recently changed
#    projects and recently changed products.
#      * Get project_ids of interest.
#      * Alleles are retrieved by 1000 designs (SQL 'IN' condition limit) and
#        filtered on project_ids previously retrieved.
#      * SQL query returns one row per allele (conditional or non-conditional)
#      * For each fetched allele do:
#        * Check if fetched allele exists in IDCC:
#          - yes: IDCC allele is updated if any change has been made in HTGT
#          - no: IDCC allele is created
#        * Synchronize allele products between HTGT and IDCC:
#          For each (HTGT - IDCC) product do:
#            - If product is related to a different IDCC allele: move
#              association to the fetched allele
#            - If product does not exist in IDCC: add it.
#
#          For each (IDCC - HTGT) product do:
#            - Delete product from IDCC
# 
# == Usage
#
# ruby load_idcc.rb [OPTIONS]
#
# -h, --help:
#     Show help.
#
# -p, --production:
#     Insert the extracted HTGT data into the I-DCC production database
#
# -t, --test:
#     Insert the extracted HTGT data into the I-DCC test database
#
# --no_genbank_files:
#     Won't load genbank files from HTGT
#
# --no_report:
#     Won't send an email containing logs of the current run
#
# --debug
#     Will print logs on screen in real time

require "rubygems"
require "getoptlong"
require "rdoc/usage"
require "oci8"
require "rest_client"
require 'net/smtp'
require "json"
require "cgi"

##
## Settings
##

TODAY = Date::today.to_s

# When reporting logs via email
SMTP_SERVER = 'mail.sanger.ac.uk'
SMTP_PORT   = 25

REPORT_SUBJECT  = 'Logs'
REPORT_FROM     = 'no-reply@sanger.ac.uk'
REPORT_TO       = {
  'Sebastien Briois'  => 'sb25@sanger.ac.uk'
}

# When pushing live:
ORA_USER    = 'eucomm_vector'
ORA_PASS    = 'eucomm_vector'
ORA_DB      = 'migp_ha.world'
IDCC_SITE   = 'http://htgt:htgt@www.i-dcc.org/dev/targ_rep/'
LOG_DIR     = '/software/team87/logs/idcc/htgt_load'
GENBANK_URL = 'http://www.sanger.ac.uk/htgt/qc/seq_view_file'

##
## Set the script options
##

@@no_genbank_files  = false # Will exclude genbank files loading
@@no_report         = false # Will exclude email report
@@debug             = false # Won't print logs on screen
@@start_date        = nil
@@end_date          = nil

# TODO: Remove "production" and "test" options when pushing live
opts = GetoptLong.new(
  [ '--help',               '-h',   GetoptLong::NO_ARGUMENT ],
  [ '--production',         '-p',   GetoptLong::NO_ARGUMENT ],
  [ '--test',               '-t',   GetoptLong::NO_ARGUMENT ],
  [ '--no_genbank_files',           GetoptLong::NO_ARGUMENT ],
  [ '--no_report',                  GetoptLong::NO_ARGUMENT ],
  [ '--debug',                      GetoptLong::NO_ARGUMENT ],
  [ '--start_date',                 GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--end_date',                   GetoptLong::OPTIONAL_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when '--help'
      RDoc::usage
    when '--production'
      @@idcc_site = IDCC_SITE
      @@ora_dbh   = OCI8.new(ORA_USER, ORA_PASS, ORA_DB)
      @@log_dir   = LOG_DIR
    when '--test'
      @@idcc_site = 'http://htgt:htgt@localhost:3000/'
      @@ora_dbh   = OCI8.new(ORA_USER, ORA_PASS, 'migp_ha.world')
      @@log_dir   = 'htgt_load'
    when '--debug'
      @@debug = true
    when '--no_genbank_files'
      @@no_genbank_files = true
    when '--no_report'
      @@no_report = true
    when '--start_date'
      @@start_date = Date::strptime(str=arg, fmt='%d/%m/%Y')
    when '--end_date'
      @@end_date = Date::strptime(str=arg, fmt='%d/%m/%Y')
  end
end


##
##  Helpers
##

def request(method, url, data = nil, datatype = "application/json", site = @@idcc_site)
  resource = RestClient::Resource.new( site )
  
  case method.upcase
  when "GET"    then resource[url].get
  when "POST"   then resource[url].post data, :content_type => datatype
  when "PUT"    then resource[url].put  data, :content_type => datatype
  when "DELETE" then resource[url].delete
  else
    raise "Method #{method} unknown when requesting url #{url}"
  end
end

def log(message)
  f = File.open("#{TODAY}/errors.txt", 'a')
  f << "#{message}\n"
  f.close()
  puts "#{message}\n" if @@debug
end

def report
  designs_file = File.open "#{TODAY}/invalid_designs.txt"
  errors_file = File.open "#{TODAY}/errors.txt"
  send_to = REPORT_TO.collect { |name, email| "#{name} <#{email}>" }.join(', ')
  
  email = <<-END_OF_MESSAGE
From: I-DCC Loading Script <#{REPORT_FROM}>
Subject: #{REPORT_SUBJECT}
To: #{send_to}

Invalid designs found:
#{designs_file.readlines}

Errors:
#{errors_file.readlines}
END_OF_MESSAGE

  designs_file.close
  errors_file.close
  begin
    Net::SMTP.start(SMTP_SERVER, SMTP_PORT) do |smtp|
      smtp.sendmail(email, REPORT_FROM, REPORT_TO.values)
    end
  rescue Exception => e
    log "Error: " + e
  end
end

class Chrono
  def initialize
    @start = nil
    @stop = nil
  end
  
  def start
    @stop  = nil
    @start = Time.now
  end
  
  def stop
    @stop = Time.now if @stop.nil?
    diff_time = @stop - @start.to_i
    puts "#{diff_time.hour - 1}h #{diff_time.min}m #{diff_time.sec}s"
  end
end

class IdccObject
  # Holds common methods for Pipeline, Design and Allele classes
  
  def initialize( args = nil )
    @ATTRIBUTES = self.class.const_get 'ATTRIBUTES'
    
    @ATTRIBUTES.each do |attr|
      if args.key? attr
        instance_variable_set("@#{attr}", args[attr])
      elsif args.key? attr.to_s
        instance_variable_set("@#{attr}", args[attr.to_s])
      end
    end
    
    return self
  end
  
  def self.get( instance_id )
    instances = self.class_eval "@@instances"
    instances.each do |instance|
      if instance.instance_eval("@#{self.name.downcase}_id").to_s == instance_id.to_s
        return instance
      end
    end
    nil
  end
  
  def self.delete( instance )
    instances = self.class_eval "@@instances"
    instances.delete( instance )
    instance = nil
  end
  
  def self.each
    instances = self.class_eval "@@instances"
    instances.each { |instance| yield instance }
    instances.length
  end
  
  def self.count
    instances = self.class_eval "@@instances"
    instances.length
  end
  
  def to_hash
    @NOT_DUMPED = self.class.const_get 'NOT_DUMPED'
    ( @ATTRIBUTES - @NOT_DUMPED ).inject({ }) do |h, attr|
      attr_value = instance_variable_get "@#{attr}"
      h[attr.to_s] = attr_value ? attr_value : ''
      h
    end
  end
  
  def to_json
    JSON.generate( {self.class.name.downcase => to_hash()} )
  end
end

class Pipeline < IdccObject
  ATTRIBUTES = [:id, :name].freeze
  ATTRIBUTES.each { |attr| attr_accessor attr }
  NOT_DUMPED = []
  
  @@instances = []
  
  def initialize( args = nil )
    pipeline = super(args)
    @@instances.push( pipeline )
    pipeline
  end
  
  # Get IDCC pipelines or create them if they do not exist.
  def self.get_or_create
    response = request( 'GET', 'pipelines.json' )
    pipeline_list = JSON.parse(response)
    
    # GET 
    if pipeline_list.size > 0
      pipeline_list.each do |pipeline|
        Pipeline.new({ :id => pipeline['id'], :name => pipeline['name'] })
      end
    # CREATE
    else
      ['KOMP-CSD', 'EUCOMM', 'KOMP-Regeneron', 'NorCOMM'].each do |pipeline|
        json = JSON.generate( {'pipeline' => { 'name' => pipeline }} )
        response = request( 'POST', 'pipelines.json', json )
        pipeline = JSON.parse( response )
        Pipeline.new({ :id => pipeline['id'], :name => pipeline['name'] })
      end
    end
  end
  
  def self.get_id_from( pipeline_name )
    @@instances.each do |pipeline|
      return pipeline.id if pipeline.name.to_s == pipeline_name
    end
  end
end

class Design < IdccObject
  ATTRIBUTES = [
    :design_id, :features, :design_type, :subtype, :subtype_description,
    :assembly_name, :chromosome, :strand, :is_valid, :invalid_msg
  ].freeze
  ATTRIBUTES.each { |attr| attr_accessor attr }
  NOT_DUMPED = []
  @@instances = []
  
  def initialize( args = nil )
    design = super(args)
    @features = {}
    design.is_valid = true
    @@instances.push( design )
    design
  end
  
  def self.retrieve_from_htgt
    query =
    """
    SELECT DISTINCT
      design.design_id,
      design.design_type,
      design.subtype,
      design.subtype_description,
      display_feature.display_feature_type,
      display_feature.feature_start,
      display_feature.feature_end,
      replace(replace(display_feature.feature_strand, '-1', '-'), '1', '+') as strand,
      mig.gnm_assembly.name,
      chromosome_dict.name
    FROM
      design
      JOIN project          ON project.design_id = design.design_id
      JOIN project_status   ON project_status.project_status_id = project.project_status_id
      JOIN feature          ON feature.design_id = design.design_id
      JOIN display_feature  ON display_feature.feature_id = feature.feature_id
      JOIN mig.gnm_assembly ON mig.gnm_assembly.id = display_feature.assembly_id
      JOIN chromosome_dict  ON chromosome_dict.chr_id = feature.chr_id
    WHERE
      project_status.order_by >= 75
      AND display_feature.assembly_id = 11
      AND display_feature.display_feature_type IN ('G3','G5','U3','U5','D3','D5')
    ORDER BY design.design_id
    """
    current_design = nil
    @@ora_dbh.exec(query) do |fetch_row|
      design_id = fetch_row[0]
      
      # 1- Same design as fetched previously
      if current_design and design_id == current_design.design_id
        next unless current_design.is_valid?
      
      # 2- New design found
      else
        design_type = fetch_row[1] == 'Del_Block' ? 'Deletion' : 'Knock Out'
        
        current_design =
        Design.new({
          :design_id           => design_id,
          :design_type         => design_type,
          :subtype             => fetch_row[2],
          :subtype_description => fetch_row[3],
          :strand              => fetch_row[7],
          :assembly_name       => fetch_row[8],
          :chromosome          => fetch_row[9]
        })
      end
      
      # Populate design with feature or set it as invalid design if 
      # current feature has already been seen in a previous row.
      feature_name  = fetch_row[4]
      feature_start = fetch_row[5]
      feature_end   = fetch_row[6]
      
      feature = current_design.features[feature_name]
      if feature.nil?
        current_design.features[feature_name] = {
          'start' => feature_start,
          'end'   => feature_end
        }
      elsif feature['start'] != feature_start
        current_design.invalid_msg = "multiple start positions found for #{feature_name}"
        current_design.is_valid = false
      elsif feature['end'] != feature_end
        current_design.invalid_msg = "multiple end positions found for #{feature_name}"
        current_design.is_valid = false
      end
    end
  end
  
  def self.each_by( step_by = 1000 )
    raise "step_by arg must be strictly positive" unless step_by > 0
    
    0.step( @@instances.length, step_by ) do |step_nb|
      yield @@instances[step_nb..(step_nb + step_by - 1)]
    end
  end
  
  # Perform validation on all valid designs (pointless on invalid designs)
  def self.validation
    Design.each do |design|
      next unless design.is_valid?
      
      # Knockout type
      if design.design_type == 'Knock Out'
        ['G3', 'G5', 'U3', 'U5', 'D3', 'D5'].each do |feature_name|
          next unless design.is_valid?
          
          feature = design.features[feature_name]
          if feature.nil?
            design.invalid_msg = "#{feature_name} is missing."
            design.is_valid = false
          elsif feature['start'].nil?
            design.invalid_msg = "#{feature_name} ``start`` is missing."
            design.is_valid = false
          elsif feature['end'].nil?
            design.invalid_msg = "#{feature_name} ``end`` is missing."
            design.is_valid = false
          end
        end
        
      # Deletion type
      else
        ['U5', 'D3', 'G3', 'G5'].each do |feature_name|
          next unless design.is_valid?
          
          feature = design.features[feature_name]
          if feature.nil?
            design.invalid_msg = "#{feature_name} is missing."
            design.is_valid = false
          elsif feature['start'].nil?
            design.invalid_msg = "#{feature_name} ``start`` is missing."
            design.is_valid = false
          elsif feature['end'].nil?
            design.invalid_msg = "#{feature_name} ``end`` is missing."
            design.is_valid = false
          end
        end
      end
      
      design.is_valid = true
    end
  end
  
  def self.log
    invalid_designs_file  = File.open("#{TODAY}/invalid_designs.txt", 'w')
    
    Design.each do |design|
      unless design.is_valid?
        invalid_designs_file << "#{design.design_id};#{design.invalid_msg}\n"
      end
    end
    
    invalid_designs_file.close
  end
  
  def is_valid?
    self.is_valid == true
  end
end

class MolecularStructure < IdccObject
  ATTRIBUTES = [
    :molecular_structure_id, :design_id, :mgi_accession_id, 
    :chromosome, :strand, :allele_symbol_superscript, 
    :design_type, :design_subtype, :subtype_description, :cassette, :backbone,
    :cassette_start, :cassette_end, :loxp_start, :loxp_end, 
    :homology_arm_start, :homology_arm_end, :targeted_trap, 
    :targeting_vectors, :es_cells, :genbank_file
  ].freeze
  ATTRIBUTES.each { |attr| attr_accessor attr }
  NOT_DUMPED = [:molecular_structure_id, :design_id, :targeted_trap]
  @@instances = []
  
  def initialize( args = nil )
    mol_struct = super(args)
    mol_struct.es_cells = []
    mol_struct.targeting_vectors = []
    mol_struct.genbank_file = {}
    @@instances.push( mol_struct )
    mol_struct
  end
  
  def to_json
    JSON.generate( { "molecular_structure" => to_hash() } )
  end
  
  def has_changed( mol_struct_hash )
    not_checked = NOT_DUMPED + [:targeting_vectors, :es_cells]
    not_checked.push(:genbank_file) if @@no_genbank_files
    
    (ATTRIBUTES - not_checked).each do |attr|
      self_value  = self.instance_variable_get "@#{attr}"
      other_value = mol_struct_hash[ attr.to_s ]
      unless self_value.to_s == other_value.to_s
        if attr.to_s == 'allele_symbol_superscript' and self_value.nil?
          self.allele_symbol_superscript = mol_struct_hash[ attr.to_s ]
          next
        end
        
        if attr.to_s == 'genbank_file'
          log "[MOL STRUCT CHANGES];#{self.molecular_structure_id};genbank_file"
        else
          log "[MOL STRUCT CHANGES];#{self.molecular_structure_id};#{attr};'#{other_value}' -> '#{self_value}'"
        end
        return true
      end
    end
    false
  end
  
  def push_to_idcc
    params = "mgi_accession_id=#{self.mgi_accession_id}"
    params += "&chromosome=#{self.chromosome}"
    params += "&strand=#{self.strand}"
    params += "&homology_arm_start=#{self.homology_arm_start}"
    params += "&homology_arm_end=#{self.homology_arm_end}"
    params += "&cassette_start=#{self.cassette_start}"
    params += "&cassette_end=#{self.cassette_end}"
    params += "&cassette=#{self.cassette}"
    params += "&backbone=#{CGI::escape( self.backbone )}"
    
    if self.loxp_start and self.loxp_end
      params += "&loxp_start=#{self.loxp_start}&loxp_end=#{self.loxp_end}"
    else
      params += "&loxp_start=null&loxp_end=null"
    end
    
    if self.allele_symbol_superscript
      params += "&allele_symbol_superscript=#{self.allele_symbol_superscript}"
    end
    
    json_response = JSON.parse(request( 'GET', "alleles.json?#{params}" ))
    mol_struct_hash = json_response[0] if json_response.length > 0
    
    # Include genbank files if script option is on
    unless @@no_genbank_files
      base_params = "?cassette=#{self.cassette}&design_id=#{self.design_id}"
      
      # Targeting vector
      begin
        params = base_params + "&backbone=#{self.backbone}"
        resource = RestClient::Resource.new( GENBANK_URL )
        targ_vec_file = resource["?#{params}"].get
      rescue RestClient::Exception => e
        targ_vec_file = ''
      end
      
      # ES Cell clone
      begin
        base_params += "&targeted_trap=1" if self.targeted_trap
        resource = RestClient::Resource.new( GENBANK_URL )
        escell_file = resource["?#{params}"].get
      rescue RestClient::Exception => e
        escell_file = ''
      end
      
      self.genbank_file = {
        :escell_clone     => escell_file,
        :targeting_vector => targ_vec_file
      }
    end
    
    # CREATE I-DCC allele if not found ...
    if mol_struct_hash.nil?
      begin
        response = request( 'POST', 'alleles.json', to_json )
        self.molecular_structure_id = JSON.parse(response)['id']
      rescue RestClient::Exception => e
        log "[MOL STRUCT CREATION];#{params};#{e.http_body}"
      end
    
    # ... or UPDATE it - if any change has been made
    else
      self.molecular_structure_id = mol_struct_hash['id']
      self.targeting_vectors      = mol_struct_hash['targeting_vectors']
      self.es_cells               = mol_struct_hash['es_cells']
      
      if has_changed( mol_struct_hash )
        begin
          response = request( 'PUT', "alleles/#{self.molecular_structure_id}.json", to_json )
        rescue RestClient::Exception => e
          log "[MOL STRUCT UPDATE];#{JSON.parse(response)}" if response
        end
      end
    end
  end
  
  def synchronize_targeting_vectors
    return unless self.molecular_structure_id
    
    query =
    """
    SELECT DISTINCT
      project.project_id,
      pcs_plate_name || '_' || pcs_well_name as intermediate_vector,
      pgdgr_plate_name || '_' || pgdgr_well_name as targeting_vector,
      is_eucomm, 
      is_komp_csd, 
      is_norcomm
    FROM
      project
      JOIN well_summary_by_di ws ON ws.project_id = project.project_id
      JOIN mgi_gene              ON mgi_gene.mgi_gene_id = project.mgi_gene_id
    WHERE
      (
        project.is_eucomm = 1
        OR project.is_komp_csd = 1
        OR project.is_norcomm = 1
      )
      AND mgi_gene.mgi_accession_id = '#{self.mgi_accession_id}'
      AND project.design_id = '#{self.design_id}'
      AND project.cassette  = '#{self.cassette}'
      AND project.backbone  = '#{self.backbone}'
      AND (pgdgr_distribute = 'yes' OR ws.epd_distribute = 'yes')
      AND pgdgr_well_name IS NOT NULL
    """
    
    begin
      cursor = @@ora_dbh.exec(query)
    rescue
      log "[TARG VEC SQL];#{query}"
      raise
    end
    
    htgt_targ_vec = []
    
    cursor.fetch do |fetch_row|
      ikmc_project_id       = fetch_row[0]
      intermediate_vector   = fetch_row[1]
      targeting_vector      = fetch_row[2]
      is_eucomm             = fetch_row[3] == 1
      is_komp_csd           = fetch_row[4] == 1
      is_norcomm            = fetch_row[5] == 1
      
      #-- Pipeline id
      pipeline_id =
      if is_eucomm then Pipeline.get_id_from('EUCOMM')
      elsif is_komp_csd then Pipeline.get_id_from('KOMP-CSD')
      elsif is_norcomm then Pipeline.get_id_from('NorCOMM')
      end
      next if pipeline_id.nil?
      
      targ_vec = TargetingVector.new({
        :molecular_structure_id => self.molecular_structure_id,
        :pipeline_id            => pipeline_id,
        :ikmc_project_id        => ikmc_project_id,
        :intermediate_vector    => intermediate_vector,
        :name                   => targeting_vector
      })
      
      begin
        targ_vec.push_to_idcc()
        targ_vec.synchronize_es_cells()
      rescue RestClient::ServerBrokeConnection
        log "[TARG VEC];#{targ_vec.to_json()};The server broke the connection \
prior to the request completing. Usually this means it crashed, or sometimes \
that your network connection was severed before it could complete."
      rescue RestClient::RequestTimeout
        log "[TARG VEC];#{targ_vec.to_json()};Request timed out"
      end
    end
  end
  
  def synchronize_es_cells
    return unless \
      self.molecular_structure_id \
      and self.targeted_trap \
      and self.allele_symbol_superscript
    
    query =
    """
    SELECT DISTINCT
      epd_well_name,
      es_cell_line
    FROM
      project
      JOIN well_summary_by_di ws ON ws.project_id = project.project_id
      JOIN mgi_gene              ON mgi_gene.mgi_gene_id = project.mgi_gene_id
    WHERE
      epd_well_name IS NOT NULL
      AND (ws.epd_distribute = 'yes' OR ws.targeted_trap = 'yes')
      AND ws.pgdgr_plate_name IS NOT NULL
      AND mgi_gene.mgi_accession_id = '#{self.mgi_accession_id}'
      AND allele_name LIKE \'%#{self.allele_symbol_superscript}%\'
    """
    
    begin
      cursor = @@ora_dbh.exec(query)
    rescue
      log "[ES CELL SQL];#{query}"
      raise
    end
    
    htgt_products = {}
    cursor.fetch do |fetch_row|
      htgt_products[fetch_row[0]] = format_parental_cell_line(fetch_row[1])
    end
    
    idcc_products = []
    unless self.es_cells.nil? or self.es_cells.empty?
      self.es_cells.each { |es_cell| idcc_products.push(es_cell['name']) }
    end
    
    #
    #  DELETE ES Cells
    #
    if (idcc_products - htgt_products.keys).length > 0
      self.es_cells.each do |es_cell|
        next if es_cell.empty?
        
        unless htgt_products.keys.include? es_cell['name']
          begin
            request( 'DELETE', "products/#{es_cell['id']}" )
          rescue RestClient::Exception => e
            log "[ES CELL DELETE];#{es_cell['id']};#{e}"
          end
        end
      end
    end
    
    #
    #  CREATE / UPDATE ES Cells
    #
    (htgt_products.keys - idcc_products).each do |product_name|
      
      # Search product in IDCC - ie. linked to another allele
      response = request( 'GET', "products.json?name=#{product_name}" )
      products_found = JSON.parse( response )
      
      json = 
      JSON.generate({
        'es_cell' => {
          'molecular_structure_id'  => self.molecular_structure_id,
          'name'                    => product_name,
          'parental_cell_line'      => htgt_products[product_name]
        }
      })
      
      #
      #  UPDATE - if changed
      #
      if products_found.length > 0
        product_found = products_found[0]
        if product_found['molecular_structure_id'] != self.molecular_structure_id \
        or product_found['parental_cell_line'] != htgt_products[product_name]
          begin
            response = request( 'PUT', "products/#{product_found['id']}.json", json )
          rescue RestClient::Exception => e
            log "[ES CELL UPDATE];#{json};#{e.http_body}"
          end
        end
      
      #
      #  CREATE
      #
      else
        begin
          response = request( 'POST', 'products.json', json )
        rescue RestClient::Exception => e
          log "[ES CELL CREATION - MOL STRUCT];#{json};#{e.http_body}"
        end
      end
    end
  end
end

class TargetingVector < IdccObject
  ATTRIBUTES = [
    :targeting_vector_id,
    :ikmc_project_id, :intermediate_vector, :name,
    :molecular_structure_id, :pipeline_id, :es_cells
  ].freeze
  ATTRIBUTES.each { |attr| attr_accessor attr }
  NOT_DUMPED = [:targeting_vector_id, :es_cells]
  @@instances = []
  
  def initialize( args = nil )
    targ_vec = super( args )
    targ_vec.es_cells = []
    @@instances.push( targ_vec )
    targ_vec
  end
  
  def to_json
    JSON.generate( { "targeting_vector" => to_hash() } )
  end
  
  def has_changed( targ_vec_hash )
    (ATTRIBUTES - NOT_DUMPED).each do |attr|
      self_value  = self.instance_variable_get "@#{attr}"
      other_value = targ_vec_hash[ attr.to_s ]
      unless self_value.to_s == other_value.to_s
        log "[TARG VEC CHANGES];#{self.targeting_vector_id};#{attr};'#{other_value}' -> '#{self_value}'"
        return true
      end
    end
    return false
  end
  
  def push_to_idcc
    # Search for an IDCC allele with IKMC project ID and targeting vector
    params = "ikmc_project_id=#{@ikmc_project_id}&name=#{@name}"
    json_response = JSON.parse(request( 'GET', "targeting_vectors.json?#{params}" ))
    targ_vec_hash = json_response[0] if json_response.length > 0
    
    # CREATE IDCC targeting vector if not found ...
    if targ_vec_hash.nil?
      begin
        response = request( 'POST', 'targeting_vectors.json', to_json )
        self.targeting_vector_id = JSON.parse(response)['id']
      rescue RestClient::Exception => e
        log "[TARG VEC CREATION];#{params};#{e.http_body}"
      end
      
    # ... or UPDATE it - if any change has been made
    else
      self.targeting_vector_id  = targ_vec_hash['id']
      self.es_cells             = targ_vec_hash['es_cells']
      if self.has_changed( targ_vec_hash )
        begin
          response = request( 'PUT', "targeting_vectors/#{self.targeting_vector_id}.json", to_json )
        rescue RestClient::Exception => e
          log "[TARG VEC UPDATE];#{self.targeting_vector_id};#{e.http_body}"
        end
      end
    end
  end
  
  def synchronize_es_cells
    query =
    """
    SELECT DISTINCT
      epd_well_name, targeted_trap, es_cell_line
    FROM
      well_summary_by_di
    WHERE
      epd_well_name IS NOT NULL
      AND epd_distribute = 'yes'
      AND project_id = #{self.ikmc_project_id}
      AND pgdgr_plate_name || '_' || pgdgr_well_name = '#{self.name}'
    """
    
    begin
      cursor = @@ora_dbh.exec(query)
    rescue
      log "[ES CELL SQL];#{query}"
      raise
    end
    
    htgt_products = {}
    cursor.fetch do |fetch_row|
      htgt_products[fetch_row[0]] = {
        :is_targeted_trap   => fetch_row[1], 
        :parental_cell_line => format_parental_cell_line( fetch_row[2] )
      }
    end
    
    idcc_products = []
    unless self.es_cells.nil? or self.es_cells.empty?
      self.es_cells.each { |es_cell| idcc_products.push(es_cell['name']) }
    end
    
    #
    #  DELETE ES Cells
    #
    if (idcc_products - htgt_products.keys).length > 0
      self.es_cells.each do |es_cell|
        next if es_cell.empty?
        
        unless htgt_products.keys.include? es_cell['name']
          begin
            request( 'DELETE', "products/#{es_cell['id']}" )
          rescue RestClient::Exception => e
            log "[ES CELL DELETE];#{es_cell['id']};#{e}"
          end
        end
      end
    end
    
    #
    #  CREATE / UPDATE ES Cells
    #
    (htgt_products.keys - idcc_products).each do |product_name|
      
      parental_cell_line = htgt_products[product_name][:parental_cell_line]
      is_targeted_trap = htgt_products[product_name][:is_targeted_trap] == true
      
      # Search product in IDCC - ie. linked to another allele
      response = request( 'GET', "products.json?name=#{product_name}" )
      products_found = JSON.parse( response )
      
      #
      #  UPDATE - if changed
      #
      if products_found.length > 0
        product_found = products_found[0]
        
        # Case 1 - Targeted trap
        if is_targeted_trap
          # Continue if nothing has changed - don't check mol struct in this case
          next if product_found['targeting_vector_id'] == self.targeting_vector_id \
          and product_found['parental_cell_line'] == parental_cell_line
          
          json = 
          JSON.generate({
            'es_cell' => {
              'targeting_vector_id' => self.targeting_vector_id,
              'name'                => product_name,
              'parental_cell_line'  => parental_cell_line
            }
          })
          
        # Case 2 - Not targeted trap
        else
          # Continue if nothing has changed
          next if product_found['molecular_structure_id'] == self.molecular_structure_id \
          and product_found['targeting_vector_id'] == self.targeting_vector_id
          
          json = 
          JSON.generate({
            'es_cell' => {
              'molecular_structure_id'  => self.molecular_structure_id,
              'targeting_vector_id'     => self.targeting_vector_id,
              'name'                    => product_name,
              'parental_cell_line'      => parental_cell_line
            }
          })
        end
        
        # Finally, push ES cell to IDCC
        begin
          response = request( 'PUT', "products/#{product_found['id']}.json", json )
        rescue RestClient::Exception => e
          log "[ES CELL UPDATE];#{product_found['id']};#{e.http_body}"
        end
      
      #
      #  CREATE
      #
      else
        json = 
        JSON.generate({
          'es_cell' => {
            'molecular_structure_id'  => self.molecular_structure_id,
            'targeting_vector_id'     => self.targeting_vector_id,
            'name'                    => product_name,
            'parental_cell_line'      => parental_cell_line
          }
        })
        begin
          response = request( 'POST', 'products.json', json )
        rescue RestClient::Exception => e
          log "[ES CELL CREATION - TARG VEC];#{json};#{e.http_body}"
        end
      end
    end
  end
end


def format_parental_cell_line( parental_cell_line )
  unless parental_cell_line.nil?
    parental_cell_line =
    case parental_cell_line
      when /JM8\s+/     then 'JM8 parental'
      when /JM8\.F6/    then 'JM8.F6'
      when /JM8\.N19/   then 'JM8.N19'
      when /JM8\.N4/    then 'JM8.N4'
      when /JM8\.AF6/   then 'JM8.AF6'
      when /JM8\.N3/    then 'JM8A1.N3'
      when /JM8A1\.N3/  then 'JM8A1.N3'
      else parental_cell_line
    end
  end
end

# Will get the project ids to filter on for finding new or udpated alleles
def get_changed_projects
  changed_projects = []
  
  # 1- Look in project_history table. This table holds added and updated
  #   projects along with a timestamp.
  
  # Filter on a period or on the last two days
  if @@start_date and @@end_date
    query_join_cond = "
      AND history_date >= TO_DATE('#{@@start_date}', 'YYYY-MM-DD')
      AND history_date <= TO_DATE('#{@@end_date}', 'YYYY-MM-DD')
    "
  else
    query_join_cond = "AND history_date >= current_date - 2"
  end
  
  query =
  """
  SELECT DISTINCT
    project.project_id
  FROM
    project
    JOIN project_history ON (
      project_history.project_id = project.project_id
      #{query_join_cond}
    )
  """
  
  @@ora_dbh.exec(query) { |row| changed_projects.push( row[0] ) }

  # 2- Compare today's dump of well_summary_by_di table to yesterday's dump.
  #   -> No timestamp in this table so need to put yesterday's dump in a file
  #      and compare to today's file
  # old_file = File.new('previous_epd_dump.txt', 'r') rescue nil
  #   new_file = File.new('current_epd_dump.txt', 'w+') # Read-write mode
  # 
  #   # Dumping today's data
  #   query =
  #   """
  #   SELECT DISTINCT project_id, epd_well_name
  #   FROM well_summary_by_di
  #   WHERE project_id IS NOT NULL AND epd_well_name IS NOT NULL
  #   ORDER BY project_id, epd_well_name
  #   """
  #   @@ora_dbh.exec(query) { |row| new_file << row.join(';') + "\n" }
  # 
  #   if old_file.nil?
  #     system('mv current_epd_dump.txt previous_epd_dump.txt')
  #     return
  #   end
  # 
  #   # Go to beginning of new_file for reading
  #   new_file.seek(0)
  # 
  # 
  #   ## Start: helpers
  #   def self.get_next_line( file )
  #     return file.readline.chomp.split(';') rescue nil
  #   end
  # 
  #   def self.add_project_id( project_id )
  #     changed_projects.push( project_id ) unless changed_projects.include? project_id
  #   end
  #   ## End: Helpers
  # 
  # 
  #   # Compare old and new files
  #   finished = false
  #   new_line = get_next_line( new_file )
  #   old_line = get_next_line( old_file )
  # 
  #   while not finished
  #     finished = true if new_line.nil? and old_line.nil?
  # 
  #     # EOF new_file
  #     if new_line.nil?
  #       old_line = get_next_line( old_file )
  #       add_project_id( old_line[0] ) if old_line
  # 
  #     # EOF old_file
  #     elsif old_line.nil?
  #       new_line = get_next_line( new_file )
  #       add_project_id( new_line[0] ) if new_line
  # 
  #     elsif new_line == old_line
  #       new_line = get_next_line(new_file)
  #       old_line = get_next_line(old_file)
  # 
  #     else
  #       new_project_id = new_line[0]
  #       old_project_id = old_line[0]
  # 
  #       if new_project_id > old_project_id
  #         add_project_id( old_project_id )
  #         old_line = get_next_line( old_file )
  # 
  #       elsif new_project_id < old_project_id
  #         add_project_id( new_project_id )
  #         new_line = get_next_line( new_file )
  # 
  #       else
  #         add_project_id( new_project_id )
  #         if new_line[1] < old_line[1]
  #           new_line = get_next_line( new_file )
  #         else
  #           old_line = get_next_line( old_file )
  #         end
  #       end
  #     end
  #   end
  #   
  #   system('mv current_epd_dump.txt previous_epd_dump.txt')

  return changed_projects
end

def load_idcc( changed_projects )
  return if changed_projects.empty?

  #--- Prepare additional query conditions
  design_filter = ""    
  Design.each_by(1000) do |design_list|
    designs_ids = []
    design_list.each do |design|
      designs_ids.push(design.design_id) if design.is_valid?
    end
    next if designs_ids.length == 0
    design_filter += "\nOR " if design_filter.length > 0
    design_filter += "project.design_id IN (#{designs_ids.join(',')})"
  end

  project_filter = ""
  projects = []
  changed_projects.each do |project_id|
    if projects.length < 1000
      projects.push( project_id )
    else
      project_filter += "\nOR " if project_filter.length > 0
      project_filter += "project.project_id IN (#{projects.join(',')})"
      projects = []
    end
  end
  if projects.length > 0
    project_filter += "\nOR " if project_filter.length > 0
    project_filter += "project.project_id IN (#{projects.join(',')})"
  end

  #--- Additional query conditions are set, let's create the query
  # Conditional and non-conditional alleles are selected in two rows.
  query =
  """
  SELECT DISTINCT
    mgi_gene.mgi_accession_id,
    project.design_id,
    project.cassette,
    project.backbone,
    ws.epd_distribute,
    ws.targeted_trap,
    allele_name
  FROM
    project
    JOIN well_summary_by_di ws ON ws.project_id = project.project_id
    JOIN mgi_gene              ON mgi_gene.mgi_gene_id = project.mgi_gene_id
  WHERE
    pgdgr_distribute = 'yes'
    AND (ws.pgdgr_well_name IS NOT NULL OR ws.epd_well_name IS NOT NULL)
  """
  query += "
    AND ( #{design_filter} )
  " unless design_filter.empty?
  query += "
    AND ( #{project_filter} )
  " unless project_filter.empty?
  
  query += "
  ORDER BY 
    mgi_gene.mgi_accession_id,
    project.design_id,
    project.cassette,
    project.backbone,
    ws.epd_distribute,
    ws.targeted_trap,
    allele_name
  "
  
  begin
    cursor = @@ora_dbh.exec(query)
  rescue
    log "[MOL STRUCT SQL];#{query}"
    raise
  end
  
  mol_struct = nil
  
  cursor.fetch do |fetch_row|
    mgi_accession_id  = fetch_row[0]
    design_id         = fetch_row[1]
    cassette          = fetch_row[2]
    backbone          = fetch_row[3]
    epd_distribute    = fetch_row[4] == 'yes'
    targeted_trap     = fetch_row[5] == 'yes'
    allele_name       = fetch_row[6]
    
    #-- Allele symbol superscript
    if epd_distribute or targeted_trap
      rxp_matches = /<sup>(tm\d.*)<\/sup>/.match( allele_name )
      allele_symbol_superscript = rxp_matches[1] if rxp_matches
    else
        allele_symbol_superscript = nil
    end
    
    new_mol_struct =
      mol_struct.nil? \
      or mol_struct.mgi_accession_id != mgi_accession_id \
      or mol_struct.design_id != design_id \
      or mol_struct.cassette != cassette \
      or mol_struct.backbone != backbone
    
    next if not new_mol_struct \
      and not epd_distribute \
      and not targeted_trap
    
    if epd_distribute and targeted_trap
      log "[DATABASE ERROR];#{mgi_accession_id};design_id #{design_id};#{cassette};#{backbone};we have epd_distribute=targeted_trap='yes'"
      next
    end
    
    # Already seen allele
    next if !new_mol_struct and allele_symbol_superscript == mol_struct.allele_symbol_superscript
    
    #-- Design features
    design    = Design.get( design_id )
    features  = design.features
    
    # Homology Arm
    homology_arm_start  = nil
    homology_arm_end    = nil
    if features['G5'] and features['G3']
      case design.strand
      when '+'
        homology_arm_start  = features['G5']['end']
        homology_arm_end    = features['G3']['start']
      when '-'
        homology_arm_start  = features['G5']['start']
        homology_arm_end    = features['G3']['end']
      end
    end
    
    # Cassette
    cassette_start  = nil
    cassette_end    = nil
    if features['U5'] and features['U3']
      case design.strand
      when '+'
        cassette_start  = features['U5']['end']
        cassette_end    = features['U3']['start']
      when '-'
        cassette_start  = features['U5']['start']
        cassette_end    = features['U3']['end']
      end
    end
    
    # LoxP, unless targeted trap
    loxp_start  = nil
    loxp_end    = nil
    unless targeted_trap
      if features['D5'] and features['D3']
        case design.strand
        when '+'
          loxp_start  = features['D5']['end']
          loxp_end    = features['D3']['start']
        when '-'
          loxp_start  = features['D5']['start']
          loxp_end    = features['D3']['end']
        end
      end
    end
    
    # Now that every field is properly formated, 
    # let's create the Molecular Structure
    mol_struct = MolecularStructure.new({
      :allele_symbol_superscript  => allele_symbol_superscript,
      :backbone                   => backbone,
      :cassette                   => cassette,
      :mgi_accession_id           => mgi_accession_id,
      :design_id                  => design_id,
      :chromosome                 => design.chromosome,
      :strand                     => design.strand,
      :design_type                => design.design_type,
      :design_subtype             => design.subtype,
      :subtype_description        => design.subtype_description,
      :homology_arm_start         => homology_arm_start,
      :homology_arm_end           => homology_arm_end,
      :cassette_start             => cassette_start,
      :cassette_end               => cassette_end,
      :loxp_start                 => loxp_start,
      :loxp_end                   => loxp_end,
      :targeted_trap              => targeted_trap
    })
    
    begin
      mol_struct.push_to_idcc()
      next unless mol_struct.molecular_structure_id
      
      if targeted_trap
        mol_struct.synchronize_es_cells()
      else
        mol_struct.synchronize_targeting_vectors()
        # Then targeting vectors will sync their own ES cells
      end
    rescue RestClient::ServerBrokeConnection
      log "[MOL STRUCT];#{mol_struct.to_json()};The server broke the connection \
prior to the request completing. Usually this means it crashed, or sometimes \
that your network connection was severed before it could complete."
    rescue RestClient::RequestTimeout
      log "[MOL STRUCT];#{mol_struct.to_json()};Request timed out"
    end
  end
end

##
##   Main script
##

def run
  system("rm -rf #{@@log_dir}/#{TODAY}")
  system("mkdir -p #{@@log_dir}/#{TODAY}")
  Dir.chdir(@@log_dir)
  
  puts "-- Loading pipelines --"
  Pipeline.get_or_create()
  Pipeline.each do |pipeline|
    puts "Pipeline loaded: id #{pipeline.id} name #{pipeline.name}"
  end

  puts "\n-- Retrieving designs --"
  Design.retrieve_from_htgt()
  Design.validation()
  Design.log()
  puts "#{Design.count} designs"
  
  puts "\n-- Retrieving new and updated projects --"
  changed_projects = get_changed_projects()
  
  unless changed_projects.empty?
    log "Changed projects: #{changed_projects.join(',')}"
    
    puts "\n-- Updating IDCC --"
    load_idcc( changed_projects )
  else
    puts "Nothing has changed since the previous run!"
  end  

  unless @@no_report
    puts "\n-- Sending email report --"
    report()
  end
end

c = Chrono.new()
c.start()
run()
c.stop()
