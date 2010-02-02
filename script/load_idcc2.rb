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
#      * SQL query returns one row per allele (conditional or non-conditional)
#      * For each fetched allele do:
#        * Check if fetched allele exists in IDCC:
#          - yes: IDCC allele is updated - if modified only
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

# When test only
@@idcc_site = 'http://htgt:htgt@localhost:3000/'
@@ora_dbh   = OCI8.new(ORA_USER, ORA_PASS, 'migp_ha.world')
@@log_dir   = 'htgt_load'

# TODO: Remove "production" and "test" options when pushing live
opts = GetoptLong.new(
  [ '--help',               '-h',   GetoptLong::NO_ARGUMENT ],
  [ '--production',         '-p',   GetoptLong::NO_ARGUMENT ],
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
##  I-DCC classes
##

class Pipeline
  attr_accessor :id, :name
  @@instances = []  
  
  def initialize( id, name )
    @id, @name = id, name
    @@instances.push( self )
    return self
  end
  
  def self.get_or_create
    response = request( 'GET', 'pipelines.json' )
    pipeline_list = JSON.parse(response)
    
    # GET 
    if pipeline_list.size > 0
      pipeline_list.each do |pipeline|
        Pipeline.new( pipeline['id'], pipeline['name'] )
      end
    # CREATE
    else
      ['KOMP-CSD', 'EUCOMM', 'KOMP-Regeneron', 'NorCOMM'].each do |pipeline|
        json = JSON.generate({ 'pipeline' => { 'name' => pipeline } })
        response = request( 'POST', 'pipelines.json', json )
        pipeline = JSON.parse( response )
        Pipeline.new( pipeline['id'], pipeline['name'] )
      end
    end
    
    @@instances.each do |pipeline|
      puts "Pipeline loaded: id #{pipeline.id} name #{pipeline.name}"
    end
  end
  
  def self.get_id_from( pipeline_name )
    @@instances.each do |pipeline|
      return pipeline.id if pipeline.name.to_s == pipeline_name
    end
  end
end

class Design
  attr_accessor :id, :design_type, :subtype, :subtype_description
  attr_accessor :assembly_name, :chromosome, :strand
  attr_accessor :homology_arm_start, :homology_arm_end
  attr_accessor :cassette_start, :cassette_end
  attr_accessor :loxp_start, :loxp_end
  attr_accessor :is_valid, :invalid_msg
  attr_accessor :features
  
  @@instances = []
  
  def initialize( design_id )
    @id = design_id
    @features = {}
    @is_valid = true
    @@instances.push( self )
    return self
  end
  
  def self.get( design_id )
    @@instances.each { |design| return design if design.id == design_id }
  end
  
  def self.each_slice( chunk_length )
    @@instances.each_slice( chunk_length ) do |design_array|
      yield design_array
    end
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
      if current_design and design_id == current_design.id
        next unless current_design.is_valid
      
      # 2- New design found
      else
        if current_design
          current_design.validate()
          current_design.set_features() if current_design.is_valid
        end
        
        current_design = Design.new( design_id )
        current_design.design_type         = fetch_row[1] == 'Del_Block' ? 'Deletion' : 'Knock Out'
        current_design.subtype             = fetch_row[2]
        current_design.subtype_description = fetch_row[3]
        current_design.strand              = fetch_row[7]
        current_design.assembly_name       = fetch_row[8]
        current_design.chromosome          = fetch_row[9]
      end
      
      # Populate design with feature or set it as invalid design if 
      # current feature has already been seen in a previous row.
      feature_name  = fetch_row[4]
      feature_start = fetch_row[5]
      feature_end   = fetch_row[6]
      
      feature = current_design.features[ feature_name ]
      if feature.nil?
        current_design.features[feature_name] = {
          'start' => feature_start,
          'end'   => feature_end
        }
      elsif feature['start'] != feature_start
        log "Design #{design_id};multiple start positions found for #{feature_name}"
        current_design.is_valid = false
      elsif feature['end'] != feature_end
        log "Design #{design_id};multiple end positions found for #{feature_name}"
        current_design.is_valid = false
      end
    end
  end
  
  def set_features
    next unless @is_valid
    
    #
    # Homology Arm
    #
    if @features['G5'] and @features['G3']
      case @strand
      when '+'
        @homology_arm_start  = @features['G5']['end']
        @homology_arm_end    = @features['G3']['start']
      when '-'
        @homology_arm_start  = @features['G5']['start']
        @homology_arm_end    = @features['G3']['end']
      end
    else
      @homology_arm_start, @homology_arm_end = nil, nil
    end
    
    #
    # Cassette
    #
    if (@design_type == 'Knock Out' and @features['U5'] and @features['U3']) \
    or (@design_type == 'Deletion' and @features['U5'] and @features['D3'])
      case @strand
      when '+'
        @cassette_start  = @features['U5']['end']
        @cassette_end    = @features['U3']['start'] if @design_type == 'Knock Out'
        @cassette_end    = @features['D3']['start'] if @design_type == 'Deletion'
      when '-'
        @cassette_start  = @features['U5']['start']
        @cassette_end    = @features['U3']['end'] if @design_type == 'Knock Out'
        @cassette_end    = @features['D3']['end'] if @design_type == 'Deletion'
      end
    else
      @cassette_start, @cassette_end = nil, nil
    end
    
    #
    # LoxP, unless targeted trap
    #
    unless @design_type == 'Deletion'
      if @features['D5'] and @features['D3']
        case @strand
        when '+'
          @loxp_start  = @features['D5']['end']
          @loxp_end    = @features['D3']['start']
        when '-'
          @loxp_start  = @features['D5']['start']
          @loxp_end    = @features['D3']['end']
        end
      end
    else
      @loxp_start, @loxp_end = nil, nil
    end
  end
  
  def validate
    return if not @is_valid
    
    # Knockout type
    if @design_type == 'Knock Out'
      ['G3', 'G5', 'U3', 'U5', 'D3', 'D5'].each do |feature_name|
        feature = @features[feature_name]
        if feature.nil?
          log "Design #{id};#{feature_name} is missing."
          @is_valid = false
        elsif feature['start'].nil?
          log "Design #{id};#{feature_name} ``start`` is missing."
          @is_valid = false
        elsif feature['end'].nil?
          log "Design #{id};#{feature_name} ``end`` is missing."
          @is_valid = false
        end
        return unless @is_valid
      end
      
    # Deletion type
    else
      ['U5', 'D3', 'G3', 'G5'].each do |feature_name|
        feature = @features[feature_name]
        if feature.nil?
          log "Design #{id};#{feature_name} is missing."
          @is_valid = false
        elsif feature['start'].nil?
          log "Design #{id};#{feature_name} ``start`` is missing."
          @is_valid = false
        elsif feature['end'].nil?
          log "Design #{id};#{feature_name} ``end`` is missing."
          @is_valid = false
        end
        return unless @is_valid
      end
    end
  end
end

class MolecularStructure
  attr_accessor :id, :mgi_accession_id
  attr_accessor :design_id, :design_type, :design_subtype, :subtype_description
  attr_accessor :chromosome, :strand, :cassette, :backbone
  attr_accessor :cassette_start, :cassette_end, :loxp_start, :loxp_end
  attr_accessor :homology_arm_start, :homology_arm_end
  attr_accessor :targeting_vectors, :es_cells, :genbank_file
  attr_accessor :targeted_trap
  
  def initialize( args )
    args.each_pair do | key, value |
      self.send("#{key}=", value) if self.respond_to?("#{key}=")
    end
    return self
  end
  
  def to_json
    JSON.generate({
      'molecular_structure' => {
        'mgi_accession_id'     => @mgi_accession_id,
        'cassette'             => @cassette,
        'backbone'             => @backbone,
        'chromosome'           => @chromosome,
        'strand'               => @strand,
        'design_type'          => @design_type,
        'design_subtype'       => @design_subtype,
        'subtype_description'  => @subtype_description,
        'homology_arm_start'   => @homology_arm_start,
        'homology_arm_end'     => @homology_arm_end,
        'cassette_start'       => @cassette_start,
        'cassette_end'         => @cassette_end,
        'loxp_start'           => @loxp_start,
        'loxp_end'             => @loxp_end,
        'genbank_file'         => @genbank_file
      }
    })
  end
  
  def has_changed( mol_struct_hash )
    if @mgi_accession_id    != mol_struct_hash['mgi_accession_id']    \
    or @design_type         != mol_struct_hash['design_type']         \
    or @design_subtype      != mol_struct_hash['design_subtype']      \
    or @subtype_description != mol_struct_hash['subtype_description'] \
    or @chromosome          != mol_struct_hash['chromosome']          \
    or @strand              != mol_struct_hash['strand']              \
    or @cassette            != mol_struct_hash['cassette']            \
    or @backbone            != mol_struct_hash['backbone']            \
    or @homology_arm_start  != mol_struct_hash['homology_arm_start']  \
    or @homology_arm_end    != mol_struct_hash['homology_arm_end']    \
    or @cassette_start      != mol_struct_hash['cassette_start']      \
    or @cassette_end        != mol_struct_hash['cassette_end']        \
    or @loxp_start          != mol_struct_hash['loxp_start']          \
    or @loxp_end            != mol_struct_hash['loxp_end']            \
    or ( @@no_genbank_files == false and @genbank_file != mol_struct_hash['genbank_file'] )
      log "[MOL STRUCT CHANGES];#{@id};"
      return true
    else
      return false
    end
  end
  
  def create
    # Used for loging/identify mol struct on error. 
    # If to_json() is used instead, you'll have the genbank file printed out
    dump_for_error = "#{@design_type} | Design ID: #{@design_id} | #{@mgi_accession_id}"
    
    begin
      response = request( 'POST', 'alleles.json', to_json() )
      @id = JSON.parse( response )['id']
    rescue RestClient::RequestFailed => e
      log "[MOL STRUCT CREATION];#{dump_for_error};#{e.http_body}"
    rescue RestClient::ServerBrokeConnection
      log "[MOL STRUCT CREATION];#{dump_for_error};The server broke the connection prior to the request completing."
    rescue RestClient::RequestTimeout
      log "[MOL STRUCT CREATION];#{dump_for_error};Request timed out"
    rescue RestClient::Exception => e
      log "[MOL STRUCT CREATION];#{dump_for_error};#{e}"
    end
  end
  
  def update( mol_struct_hash )
    # Used for loging/identify mol struct on error. 
    # If to_json() is used instead, you'll have the genbank file printed out
    dump_for_error = "#{@design_type} | Design ID: #{@design_id} | #{@mgi_accession_id}"
    
    @id                = mol_struct_hash['id']
    @targeting_vectors = mol_struct_hash['targeting_vectors']
    @es_cells          = mol_struct_hash['es_cells']
    
    if has_changed( mol_struct_hash )
      begin
        response = request( 'PUT', "alleles/#{@id}.json", to_json() )
      rescue RestClient::RequestFailed
        if response
          log "[MOL STRUCT UPDATE];#{JSON.parse(response)}"
        else
          log "[MOL STRUCT UPDATE];#{dump_for_error};#{e.http_body}"
        end
      rescue RestClient::ServerBrokeConnection
        log "[MOL STRUCT UPDATE];#{dump_for_error};The server broke the connection prior to the request completing."
      rescue RestClient::RequestTimeout
        log "[MOL STRUCT UPDATE];#{dump_for_error};Request timed out"
      rescue RestClient::Exception => e
        log "[MOL STRUCT UPDATE];#{dump_for_error};#{e}"
      end
    end
  end
  
  def search
    params =  "mgi_accession_id=#{@mgi_accession_id}"
    params += "&chromosome=#{@chromosome}&strand=#{@strand}"
    params += "&homology_arm_start=#{@homology_arm_start}"
    params += "&homology_arm_end=#{@homology_arm_end}"
    params += "&cassette_start=#{@cassette_start}"
    params += "&cassette_end=#{@cassette_end}"
    params += "&cassette=#{@cassette}"
    params += "&backbone=#{CGI::escape( @backbone )}"
    
    unless @loxp_start.nil? or @loxp_end.nil?
      params += "&loxp_start=#{@loxp_start}&loxp_end=#{@loxp_end}"
    else
      params += "&loxp_start=null&loxp_end=null" # important!
    end
    
    json_response = JSON.parse(request( 'GET', "alleles.json?#{params}" ))
    return json_response[0] if json_response.length > 0
  end
  
  def get_genbank_files
    # Targeting vector
    url = GENBANK_URL + "?design_id=#{@design_id}&cassette=#{@cassette}&backbone=#{@backbone}"
    targ_vec_file = RestClient::get( url ) rescue ''
    
    # ES Cell clone
    url = GENBANK_URL + "?design_id=#{@design_id}&cassette=#{@cassette}"
    url += "&targeted_trap=1" if @targeted_trap
    escell_file = RestClient::get( url ) rescue ''
    
    @genbank_file = {
      :escell_clone     => escell_file,
      :targeting_vector => targ_vec_file
    }
  end
  
  def push_to_idcc
    # Include genbank files if script option is on
    get_genbank_files() unless @@no_genbank_files
    
    existing_mol_struct = search()
    existing_mol_struct.nil? ? create() : update( existing_mol_struct )
  end
  
  def synchronize_targeting_vectors
    return unless @id
    
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
      AND mgi_gene.mgi_accession_id = '#{@mgi_accession_id}'
      AND project.design_id = '#{@design_id}'
      AND project.cassette  = '#{@cassette}'
      AND project.backbone  = '#{@backbone}'
      AND (pgdgr_distribute = 'yes' OR ws.epd_distribute = 'yes')
      AND pgdgr_well_name IS NOT NULL
    """
    begin
      cursor = @@ora_dbh.exec(query)
    rescue
      log "[TARG VEC SQL];#{query}"
      raise
    end
    
    htgt_targ_vec_list = []
    
    cursor.fetch do |fetch_row|
      ikmc_project_id = fetch_row[0]
      int_vec         = fetch_row[1]
      targ_vec        = fetch_row[2]
      is_eucomm       = fetch_row[3] == 1
      is_komp_csd     = fetch_row[4] == 1
      is_norcomm      = fetch_row[5] == 1
      
      # Get pipeline ID
      pipeline_id =
      if    is_eucomm   then Pipeline.get_id_from('EUCOMM')
      elsif is_komp_csd then Pipeline.get_id_from('KOMP-CSD')
      elsif is_norcomm  then Pipeline.get_id_from('NorCOMM')
      end
      next if pipeline_id.nil?
      
      # Create new targeting vector instance
      tv = TargetingVector.new({
        :molecular_structure_id => @id,
        :pipeline_id            => pipeline_id,
        :ikmc_project_id        => ikmc_project_id,
        :intermediate_vector    => int_vec,
        :name                   => targ_vec,
        :es_cells               => []
      })
      
      # Create or update targeting vector and its ES cells in I-DCC
      tv.push_to_idcc()
      tv.synchronize_es_cells()
      
      # Keep track of HTGT's targeting vectors fetched
      htgt_targ_vec_list.push( targ_vec )
    end
    
    # DELETE targ vec if no longer exist in HTGT
    @targeting_vectors.each do |targ_vec|
      unless htgt_targ_vec_list.include? targ_vec['name']
        begin
          request( 'DELETE', "targeting_vectors/#{targ_vec['id']}" )
        rescue RestClient::RequestFailed => e
          log "[TARG VEC DELETE];#{targ_vec['id']};#{e.http_body}"
        end
      end
    end
  end
  
  def synchronize_es_cells
    return unless @id and @targeted_trap
    
    query =
    """
    SELECT DISTINCT
      epd_well_name,
      es_cell_line,
      allele_name
    FROM
      project
      JOIN well_summary_by_di ws ON ws.project_id = project.project_id
      JOIN mgi_gene              ON mgi_gene.mgi_gene_id = project.mgi_gene_id
    WHERE
      epd_well_name IS NOT NULL
      AND ws.targeted_trap = 'yes'
      AND ws.pgdgr_well_name IS NOT NULL
      AND mgi_gene.mgi_accession_id = '#{@mgi_accession_id}'
    """
    
    begin
      cursor = @@ora_dbh.exec(query)
    rescue
      log "[ES CELL SQL];#{query}"
      raise
    end
    
    htgt_products = {}
    idcc_products = []
    
    # Fetch HTGT ES Cells
    cursor.fetch do |fetch_row|
      htgt_products[fetch_row[0]] = {
        :parental_cell_line        => format_parental_cell_line( fetch_row[1] ),
        :allele_symbol_superscript => format_allele_symbol_superscript( fetch_row[2] )
      }
    end
    
    # Dump Molecular Structure's ES Cells names into idcc_products list
    # Those are retrieved from I-DCC when searching for a similar mol struct
    unless @es_cells.nil? or @es_cells.empty?
      @es_cells.each { |es_cell| idcc_products.push(es_cell['name']) }
    end
    
    #
    #  DELETE ES Cells
    #
    if (idcc_products - htgt_products.keys).length > 0
      @es_cells.each do |es_cell|
        next if es_cell.empty?
        
        unless htgt_products.keys.include? es_cell['name']
          begin
            request( 'DELETE', "products/#{es_cell['id']}" )
          rescue RestClient::RequestFailed => e
            log "[ES CELL DELETE];#{es_cell['id']};#{e.http_body}"
          end
        end
      end
    end
    
    #
    #  CREATE or UPDATE ES Cells
    #
    (htgt_products.keys - idcc_products).each do |product_name|
      es_cell = EsCell.new({
        :molecular_structure_id    => @id,
        :name                      => product_name,
        :parental_cell_line        => htgt_products[product_name][:parental_cell_line],
        :allele_symbol_superscript => htgt_products[product_name][:allele_symbol_superscript]
      })
      existing_es_cell = es_cell.search()
      
      if existing_es_cell
        es_cell.id                  = existing_es_cell['id']
        es_cell.targeting_vector_id = existing_es_cell['targeting_vector_id']
        es_cell.update() if es_cell.has_changed( existing_es_cell, true )
      else
        es_cell.create()
      end
    end
  end
end

class TargetingVector
  attr_accessor :id, :pipeline_id, :molecular_structure_id
  attr_accessor :ikmc_project_id, :intermediate_vector, :name
  attr_accessor :es_cells
  
  def initialize( args )
    args.each_pair do | key, value |
      self.send("#{key}=", value) if self.respond_to?("#{key}=")
    end
    return self
  end
  
  def to_json
    JSON.generate({ 
      'targeting_vector' => {
        'pipeline_id'             => @pipeline_id,
        'molecular_structure_id'  => @molecular_structure_id,
        'ikmc_project_id'         => @ikmc_project_id,
        'intermediate_vector'     => @intermediate_vector,
        'name'                    => @name
      }
    })
  end
  
  def has_changed( targ_vec_hash )
    targ_vec_hash.each_pair do | key, value |
      next unless self.instance_variable_defined? "@#{key}"
      self_value = self.instance_variable_get "@#{key}"
      if self_value.to_s != value.to_s
        log "[TARG VEC CHANGES];#{@id}; #{key}: #{value} -> #{self_value}"
        return true
      end
    end
    return false
  end
  
  def search
    params = "ikmc_project_id=#{@ikmc_project_id}&name=#{@name}"
    
    response = request( 'GET', "targeting_vectors.json?#{params}" )
    json_response = JSON.parse( response )
    return json_response[0] if json_response.length > 0
  end
  
  def create
    begin
      response = request( 'POST', 'targeting_vectors.json', to_json() )
      @id = JSON.parse(response)['id']
    rescue RestClient::RequestFailed => e
      log "[TARG VEC CREATION];#{to_json()};#{e.http_body}"
    rescue RestClient::ServerBrokeConnection
      log "[TARG VEC CREATION];#{to_json()};The server broke the connection prior to the request completing."
    rescue RestClient::RequestTimeout
      log "[TARG VEC CREATION];#{to_json()};Request timed out"
    rescue RestClient::Exception => e
      log "[TARG VEC CREATION];#{to_json()};#{e}"
    end
  end
  
  def update( targ_vec_hash )
    @id       = targ_vec_hash['id']
    @es_cells = targ_vec_hash['es_cells']
    
    if has_changed( targ_vec_hash )
      begin
        response = request( 'PUT', "targeting_vectors/#{@id}.json", to_json() )
      rescue RestClient::RequestFailed => e
        log "[TARG VEC UPDATE];#{to_json()};#{e.http_body}"
      rescue RestClient::ServerBrokeConnection
        log "[TARG VEC UPDATE];#{to_json()};The server broke the connection prior to the request completing."
      rescue RestClient::RequestTimeout
        log "[TARG VEC UPDATE];#{to_json()};Request timed out"
      rescue RestClient::Exception => e
        log "[TARG VEC UPDATE];#{to_json()};#{e}"
      end
    end
  end
  
  def push_to_idcc
    existing_targ_vec = search()
    existing_targ_vec.nil? ? create() : update( existing_targ_vec )
  end
  
  def synchronize_es_cells
    query =
    """
    SELECT DISTINCT
      epd_well_name,
      targeted_trap,
      es_cell_line,
      allele_name
    FROM
      well_summary_by_di
    WHERE
      epd_well_name IS NOT NULL
      AND project_id = #{@ikmc_project_id}
      AND pgdgr_plate_name || '_' || pgdgr_well_name = '#{@name}'
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
        :is_targeted_trap           => fetch_row[1], 
        :parental_cell_line         => format_parental_cell_line( fetch_row[2] ),
        :allele_symbol_superscript  => format_allele_symbol_superscript( fetch_row[3] )
      }
    end
    
    idcc_products = []
    unless @es_cells.nil? or @es_cells.empty?
      @es_cells.each { |es_cell| idcc_products.push(es_cell['name']) }
    end
    
    #
    #  DELETE ES Cells
    #
    if (idcc_products - htgt_products.keys).length > 0
      @es_cells.each do |es_cell|
        next if es_cell.empty?
        
        unless htgt_products.keys.include? es_cell['name']
          begin
            request( 'DELETE', "products/#{es_cell['id']}" )
          rescue RestClient::RequestFailed => e
            log "[ES CELL DELETE];#{es_cell['id']};#{e}"
          end
        end
      end
    end
    
    #
    #  CREATE or UPDATE ES Cells
    #
    (htgt_products.keys - idcc_products).each do |product_name|
      es_cell = EsCell.new({
        :targeting_vector_id       => @id,
        :name                      => product_name,
        :parental_cell_line        => htgt_products[product_name][:parental_cell_line],
        :allele_symbol_superscript => htgt_products[product_name][:allele_symbol_superscript]
      })
      existing_es_cell = es_cell.search()
      
      # CREATE
      if existing_es_cell.nil?
        es_cell.molecular_structure_id = @molecular_structure_id
        es_cell.create()
      # UPDATE - if changed
      else
        es_cell.id = existing_es_cell['id']
        is_targeted_trap = htgt_products[product_name][:is_targeted_trap] == true
        if es_cell.has_changed( existing_es_cell, is_targeted_trap )
          es_cell.update()
        end
      end
    end
  end
end

class EsCell
  attr_accessor :id
  attr_accessor :molecular_structure_id, :targeting_vector_id
  attr_accessor :name, :parental_cell_line, :allele_symbol_superscript
  
  def initialize( args )
    @molecular_structure_id, @targeting_vector_id = nil, nil
    args.each_pair do | key, value |
      self.send("#{key}=", value) if self.respond_to?("#{key}=")
    end
    return self
  end
  
  def to_json
    es_cell_hash = {
      'parental_cell_line'        => @parental_cell_line,
      'name'                      => @name,
      'allele_symbol_superscript' => @allele_symbol_superscript
    }
    unless @molecular_structure_id.nil?
      es_cell_hash.update({ 'molecular_structure_id' => @molecular_structure_id })
    end
    unless @targeting_vector_id.nil?
      es_cell_hash.update({ 'targeting_vector_id' => @targeting_vector_id })
    end
    
    JSON.generate({ 'es_cell' => es_cell_hash })
  end
  
  def has_changed( es_cell_hash, is_targeted_trap )
    if is_targeted_trap
      if @targeting_vector_id       != es_cell_hash['targeting_vector_id']  \
      or @parental_cell_line        != es_cell_hash['parental_cell_line']   \
      or @allele_symbol_superscript != es_cell_hash['allele_symbol_superscript']
        return true
      end
    else
      if @molecular_structure_id    != es_cell_hash['molecular_structure_id'] \
      or @targeting_vector_id       != es_cell_hash['targeting_vector_id']    \
      or @parental_cell_line        != es_cell_hash['parental_cell_line']     \
      or @allele_symbol_superscript != es_cell_hash['allele_symbol_superscript']
        return true
      end
    end  
    return false
  end
  
  def search
    begin
      response = request( 'GET', "products.json?name=#{@name}" )
      product_list = JSON.parse( response )
      return product_list.length > 0 ? product_list[0] : nil
    rescue RestClient::ResourceNotFound
      return nil
    end
  end
  
  def create
    begin
      response = request( 'POST', 'products.json', to_json() )
    rescue RestClient::RequestFailed => e
      log "[ES CELL CREATION];#{to_json()};#{e.http_body}"
    rescue RestClient::ServerBrokeConnection
      log "[ES CELL CREATION];#{to_json()};The server broke the connection prior to the request completing."
    rescue RestClient::RequestTimeout
      log "[ES CELL CREATION];#{to_json()};Request timed out"
    rescue RestClient::Exception => e
      log "[ES CELL CREATION];#{to_json()};#{e}"
    end
  end
  
  def update
    begin
      response = request( 'PUT', "products/#{@id}.json", to_json() )
    rescue RestClient::RequestFailed => e
      log "[ES CELL UPDATE];#{to_json()};#{e.http_body}"
    rescue RestClient::ServerBrokeConnection
      log "[ES CELL UPDATE];#{to_json()};The server broke the connection prior to the request completing."
    rescue RestClient::RequestTimeout
      log "[ES CELL UPDATE];#{to_json()};Request timed out"
    rescue RestClient::Exception => e
      log "[ES CELL UPDATE];#{to_json()};#{e}"
    end
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
  f << "[Time.now.strftime('%d/%m/%Y - %H:%M:%S')] #{message}\n"
  f.close()
  puts "#{message}\n" if @@debug
end

def format_allele_symbol_superscript( allele_name )
  rxp_matches = /<sup>(tm\d.*)<\/sup>/.match( allele_name )
  return rxp_matches[1] if rxp_matches
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
  Design.each_slice(1000) do |design_list|
    designs_ids = []
    design_list.each do |design|
      designs_ids.push(design.id) if design.is_valid
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
    ws.targeted_trap
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
    ws.targeted_trap,
    ws.epd_distribute
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
    
    if epd_distribute and targeted_trap
      log "[DATABASE ERROR];#{mgi_accession_id};design_id #{design_id};#{cassette};#{backbone};epd_distribute = targeted_trap = 'yes'"
      next
    end
    
    next if not mol_struct.nil?                           \
      and mol_struct.mgi_accession_id == mgi_accession_id \
      and mol_struct.design_id        == design_id        \
      and mol_struct.cassette         == cassette         \
      and mol_struct.backbone         == backbone         \
      and not epd_distribute                              \
      and not targeted_trap
    
    design = Design.get( design_id )
    
    mol_struct_hash = {
      :mgi_accession_id     => mgi_accession_id,
      :cassette             => cassette,
      :backbone             => backbone,
      :design_id            => design_id,
      :chromosome           => design.chromosome,
      :strand               => design.strand,
      :design_type          => design.design_type,
      :design_subtype       => design.subtype,
      :subtype_description  => design.subtype_description,
      :homology_arm_start   => design.homology_arm_start,
      :homology_arm_end     => design.homology_arm_end,
      :cassette_start       => design.cassette_start,
      :cassette_end         => design.cassette_end,
      :targeted_trap        => targeted_trap,
      :loxp_start           => nil,
      :loxp_end             => nil,
      :es_cells             => [],
      :targeting_vectors    => [],
      :genbank_file         => {}
    }
    
    unless targeted_trap
      mol_struct_hash.update({
        :loxp_start => design.loxp_start,
        :loxp_end   => design.loxp_end
      })
    end
    
    # Create molecular structure
    mol_struct = MolecularStructure.new( mol_struct_hash )
    mol_struct.push_to_idcc()
    next unless mol_struct.id
    
    if targeted_trap
      # No targeting vector will be linked to this mol_struct but some
      # ES Cells will be. Let's find them.
      mol_struct.synchronize_es_cells()
    else
      # Some targeting vector will be linked to this mol_struct.
      # They will sync their own ES cells.
      mol_struct.synchronize_targeting_vectors()
    end
  end
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

##
##   Main script
##

def run
  system("rm -rf #{@@log_dir}/#{TODAY}")
  system("mkdir -p #{@@log_dir}/#{TODAY}")
  Dir.chdir(@@log_dir)
  
  puts "-- Loading pipelines --"
  Pipeline.get_or_create()

  puts "\n-- Retrieving designs --"
  Design.retrieve_from_htgt()
    
  puts "\n-- Retrieving new and updated projects --"
  changed_projects = get_changed_projects()
  
  unless changed_projects.empty?
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

start = Time.now
run()
stop = Time.now
diff_time = stop - start.to_i
puts "#{diff_time.hour - 1}h #{diff_time.min}m #{diff_time.sec}s"
