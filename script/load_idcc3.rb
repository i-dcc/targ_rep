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
# --skip_genbank_files:
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
IDCC_SITE   = 'http://htgt:htgt@htgt.internal.sanger.ac.uk:4002/labs/targ_rep'
LOG_DIR     = '/software/team87/logs/idcc/htgt_load'
GENBANK_URL = 'http://www.sanger.ac.uk/htgt/qc/seq_view_file'

##
## Set the script options
##

@@skip_mol_struct     = false # Will exclude molecular structures loading
@@skip_genbank_files  = false # Will exclude genbank files loading
@@skip_targ_vec       = false # Will exclude targeting vectors loading
@@skip_es_cell        = false # Will exclude ES cells loading

@@no_report = false # Will exclude email report
@@debug     = false # Won't print logs on screen
@@start_date, @@end_date = nil, nil

# When test only
@@idcc_site = 'http://htgt:htgt@localhost:3000/'
@@ora_dbh   = OCI8.new(ORA_USER, ORA_PASS, 'migp_ha.world')
@@log_dir   = 'htgt_load'

# TODO: Remove "production" and "test" options when pushing live
opts = GetoptLong.new(
  [ '--help',               '-h',   GetoptLong::NO_ARGUMENT ],
  [ '--production',         '-p',   GetoptLong::NO_ARGUMENT ],
  [ '--skip_mol_struct',            GetoptLong::NO_ARGUMENT ],
  [ '--skip_genbank_files',         GetoptLong::NO_ARGUMENT ],
  [ '--skip_targ_vec',              GetoptLong::NO_ARGUMENT ],
  [ '--skip_es_cell',               GetoptLong::NO_ARGUMENT ],
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
    when '--skip_mol_struct'
      @@skip_mol_struct = true
    when '--skip_genbank_files'
      @@skip_genbank_files = true
    when '--skip_targ_vec'
      @@skip_targ_vec = true
    when '--skip_es_cell'
      @@skip_es_cell = true
    when '--no_report'
      @@no_report = true
    when '--start_date'
      @@start_date = Date::strptime(str=arg, fmt='%d/%m/%Y')
    when '--end_date'
      @@end_date = Date::strptime(str=arg, fmt='%d/%m/%Y')
  end
end


##
##    I-DCC classes
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
  attr_accessor :floxed_start_exon, :floxed_end_exon
  attr_accessor :cassette_start, :cassette_end, :loxp_start, :loxp_end
  attr_accessor :homology_arm_start, :homology_arm_end
  attr_accessor :is_valid, :invalid_msg
  attr_accessor :features
  
  def initialize( args )
    args.each_pair do | key, value |
      self.send("#{key}=", value) if self.respond_to?("#{key}=")
    end
    return self
  end
  
  def self.get( design_id )
    @@design_cache[design_id]
  end
  
  def self.push_to_cache( design )
    @@design_cache[design.id] = design
  end
  
  def self.get_sql_query_htgt
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
      JOIN project ON project.design_id = design.design_id
      JOIN project_status ON 
        project_status.project_status_id = project.project_status_id 
        AND project_status.order_by >= 75
      JOIN feature ON feature.design_id = design.design_id
      JOIN display_feature ON
        display_feature.feature_id = feature.feature_id 
        AND display_feature.assembly_id = 11 
        AND display_feature.display_feature_type IN ('G3','G5','U3','U5','D3','D5')
      JOIN mig.gnm_assembly ON mig.gnm_assembly.id = display_feature.assembly_id
      JOIN chromosome_dict ON chromosome_dict.chr_id = feature.chr_id
    ORDER BY design.design_id
    """
  end
  
  def self.retrieve_from_htgt
    cursor = @@ora_dbh.exec( get_sql_query_htgt )
    
    current_design = nil
    cursor.fetch do |fetch_row|
      design_id = fetch_row[0]
      
      # 1- Same design as fetched previously
      if current_design and design_id == current_design.id
        next unless current_design.is_valid
      
      # 2- New design found
      else
        if current_design and current_design.validate()
          current_design.set_features()
          current_design.set_exons()
          push_to_cache( current_design )
        end
        
        #FIXME: What about 'Ins_Block/Ins_Location' as a design type? - treat as a deletion.
        design_type = fetch_row[1] == 'Del_Block' ? 'Deletion' : 'Knock Out'
        design_hash = {
          :id                   => design_id,
          :design_type          => design_type,
          :subtype              => fetch_row[2],
          :subtype_description  => fetch_row[3],
          :strand               => fetch_row[7],
          :assembly_name        => fetch_row[8],
          :chromosome           => fetch_row[9],
          :floxed_start_exon    => nil,
          :floxed_end_exon      => nil,
          :features             => {},
          :is_valid             => true
        }
        current_design = Design.new( design_hash )
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
    #FIXME: Insertions?
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
    # LoxP, unless Deletion
    #
    #FIXME: Insertions?
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
  
  def set_exons
    if @strand == '+'
      strand = '1'
      chr_start = @cassette_end
      if @loxp_start
        chr_end = @loxp_start
      else
        chr_end = @homology_arm_end
      end
    elsif @strand == '-'
      strand = '-1'
      chr_end = @cassette_end
      if @loxp_start
        chr_start = @loxp_start
      else
        chr_start = @homology_arm_end
      end
    end
    
    query =
    """
    SELECT ensembl_exon_stable_id
    FROM display_exon
    WHERE
      chr_name = '#{@chromosome}'
      AND chr_strand = #{strand}
      AND 
      (
        chr_start = (
          SELECT MIN(chr_start)
          FROM display_exon
          WHERE
            chr_name = '#{@chromosome}'
            AND chr_strand = #{strand}
            AND chr_start >= #{chr_start}
        )
        OR chr_end = (
          SELECT MAX(chr_end)
          FROM display_exon
          WHERE 
            chr_name = '#{@chromosome}'
            AND chr_strand = #{strand}
            AND chr_end <= #{chr_end}
        )
      )
      ORDER BY chr_start, chr_end
    """
    
    row_number = 1
    @@ora_dbh.exec( query ) do |fetch_row|
      if row_number == 1
        @floxed_start_exon = fetch_row[0]
      else
        @floxed_end_exon = fetch_row[0]
      end
      row_number += 1
    end
    
    @floxed_end_exon = @floxed_start_exon if @floxed_end_exon.nil?
  end
  
  def validate
    return false unless @is_valid
    
    # Knockout type
    #FIXME: Insertions?
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
        return false unless @is_valid
      end
      
    # Deletion type
    #FIXME: Insertions?
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
        return false unless @is_valid
      end
    end
    
    return true
  end
end

class MolecularStructure
  attr_accessor :id, :mgi_accession_id
  attr_accessor :design_id, :design_type, :design_subtype, :subtype_description
  attr_accessor :chromosome, :strand, :cassette, :backbone
  attr_accessor :floxed_start_exon, :floxed_end_exon
  attr_accessor :cassette_start, :cassette_end, :loxp_start, :loxp_end
  attr_accessor :homology_arm_start, :homology_arm_end
  attr_accessor :targeted_trap
  
  def initialize( args )
    args.each_pair do | key, value |
      self.send("#{key}=", value) if self.respond_to?("#{key}=")
    end
    return self
  end
  
  def eql?( args )
    args.each_pair do |key, value|
      next unless self.instance_variable_defined? "@#{key}"
      return false if self.instance_variable_get("@#{key}") != value
    end
  end
  
  def to_json
    JSON.generate({
      'molecular_structure' => {
        'mgi_accession_id'     => @mgi_accession_id,
        'project_design_id'    => @design_id,
        'cassette'             => @cassette,
        'backbone'             => @backbone,
        'chromosome'           => @chromosome,
        'strand'               => @strand,
        'design_type'          => @design_type,
        'design_subtype'       => @design_subtype,
        'subtype_description'  => @subtype_description,
        'floxed_start_exon'    => @floxed_start_exon,
        'floxed_end_exon'      => @floxed_end_exon,
        'homology_arm_start'   => @homology_arm_start,
        'homology_arm_end'     => @homology_arm_end,
        'cassette_start'       => @cassette_start,
        'cassette_end'         => @cassette_end,
        'loxp_start'           => @loxp_start,
        'loxp_end'             => @loxp_end
      }
    })
  end
  
  def self.get_sql_query_htgt
    """
    SELECT DISTINCT
      mgi_gene.mgi_accession_id,
      project.design_id,
      project.project_id,
      project.cassette,
      project.backbone,
      ws.epd_distribute,
      ws.targeted_trap
    FROM
      project
      JOIN project_status ON
        project_status.project_status_id = project.project_status_id
        AND project_status.order_by >= 75
      JOIN well_summary_by_di ws ON ws.project_id = project.project_id
      JOIN mgi_gene              ON mgi_gene.mgi_gene_id = project.mgi_gene_id
    WHERE
      (
        project.is_eucomm = 1
        OR project.is_komp_csd = 1
        OR project.is_norcomm = 1
      )
    ORDER BY
      mgi_gene.mgi_accession_id,
      project.design_id,
      project.cassette,
      project.backbone,
      ws.epd_distribute,
      ws.targeted_trap
    """
  end
  
  def self.create_or_update
    begin
      puts "Querying HTGT..."
      cursor = @@ora_dbh.exec( get_sql_query_htgt )
      puts "Done."
    rescue
      log "[MOL STRUCT SQL];#{get_sql_query_htgt}"
      raise
    end
    
    prev_mgi_accession_id, prev_design_id = nil, nil
    prev_cassette, prev_backbone = nil, nil
    
    cursor.fetch do |fetch_row|
      mgi_accession_id  = fetch_row[0]
      design_id         = fetch_row[1]
      project_id        = fetch_row[2]
      cassette          = fetch_row[3]
      backbone          = fetch_row[4]
      epd_distribute    = fetch_row[5] == 'yes'
      targeted_trap     = fetch_row[6] == 'yes'
      
      design = Design.get( design_id )
      if design.nil?
        log "[MOL STRUCT SKIP] Could not find design #{design_id}"
        next
      end
      
      unless design.is_valid
        log "[MOL STRUCT SKIP] Design #{design_id} is invalid"
        next
      end
      
      unless @@changed_projects.include? project_id
        log "[MOL STRUCT SKIP] Project #{project_id} has not changed"
        next
      end
      
      if epd_distribute and targeted_trap
        log "[DATABASE ERROR];#{mgi_accession_id};design_id #{design_id};#{cassette};#{backbone};epd_distribute = targeted_trap = 'yes'"
        next
      end
      
      next if prev_mgi_accession_id == mgi_accession_id \
      and prev_design_id            == design_id        \
      and prev_cassette             == cassette         \
      and prev_backbone             == backbone         \
      and not epd_distribute                            \
      and not targeted_trap
      
      prev_mgi_accession_id, prev_design_id = mgi_accession_id, design_id
      prev_cassette, prev_backbone = cassette, backbone
      
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
        :floxed_start_exon    => design.floxed_start_exon,
        :floxed_end_exon      => design.floxed_end_exon,
        :homology_arm_start   => design.homology_arm_start,
        :homology_arm_end     => design.homology_arm_end,
        :cassette_start       => design.cassette_start,
        :cassette_end         => design.cassette_end,
        :targeted_trap        => targeted_trap
      }
      
      #FIXME: Insertions? - put the loxp in as nil by default
      #if design.design_type == 'Deletion' or targeted_trap
      if targeted_trap
        mol_struct_hash.update({ :loxp_start => nil, :loxp_end => nil })
      else
        mol_struct_hash.update({
          :loxp_start => design.loxp_start,
          :loxp_end   => design.loxp_end
        })
      end
      
      # Create molecular structure
      mol_struct = MolecularStructure.new( mol_struct_hash )
      mol_struct.push_to_idcc()
      next unless mol_struct.id
      
      push_to_cache( mol_struct )
    end
  end
  
  def self.push_to_cache( mol_struct )
    @@mol_struct_cache[mol_struct.id] = mol_struct
  end
  
  def self.find( mgi_accession_id, design_id, cassette, backbone, targeted_trap )
    design = Design.get( design_id )
    
    # Search in cache
    @@mol_struct_cache.each_pair do |id, mol_struct|
      if mol_struct.mgi_accession_id  == mgi_accession_id  \
      and mol_struct.design_id        == design_id         \
      and mol_struct.cassette         == cassette          \
      and mol_struct.backbone         == backbone

        #FIXME: What about insertions?

        # Design is a Deletion or a targeted trap
        if design.design_type == 'Deletion' or targeted_trap == true
          if mol_struct.loxp_start.nil? and mol_struct.loxp_end.nil?
            return mol_struct
          end
        
        # Design is a Knock Out
        elsif mol_struct.loxp_start == design.loxp_start and mol_struct.loxp_end == design.loxp_end
          return mol_struct
        end
      end
    end
    
    # Search through webservice
    mol_struct = search( mgi_accession_id, design_id, cassette, backbone, false )
    return MolecularStructure.new( mol_struct ) unless mol_struct.nil?
    
    raise "Can't find molecular structure (#{design.design_type})
    mgi_accession_id='#{mgi_accession_id}'
    AND project_design_id=#{design_id}
    AND cassette='#{cassette}'
    AND backbone='#{backbone}'
    AND loxp_start=#{design.loxp_start}
    AND loxp_end=#{design.loxp_end}"
  end
  
  def self.search( mgi_accession_id, design_id, cassette, backbone, targeted_trap )
    design = Design.get( design_id )
    
    params =  "mgi_accession_id=#{mgi_accession_id}"
    params += "&project_design_id=#{design_id}"
    params += "&cassette=#{cassette}"
    params += "&backbone=#{CGI::escape( backbone )}"
    
    # FIXME: Insertions?
    if design.design_type == 'Deletion' or targeted_trap == true
      params += "&loxp_start=null&loxp_end=null" # important!
    else
      params += "&loxp_start=#{design.loxp_start}&loxp_end=#{design.loxp_end}"
    end
    
    json_response = JSON.parse(request( 'GET', "alleles.json?#{params}" ))
    return json_response[0] if json_response.length > 0
  end
  
  def create
    begin
      response = request( 'POST', 'alleles.json', to_json() )
      @id = JSON.parse( response )['id']
    rescue RestClient::RequestFailed => e
      log "[MOL STRUCT CREATION];#{to_json()};#{e.http_body}\n"
    rescue RestClient::ServerBrokeConnection
      log "[MOL STRUCT CREATION];#{to_json()};The server broke the connection prior to the request completing."
    rescue RestClient::RequestTimeout
      log "[MOL STRUCT CREATION];#{to_json()};Request timed out"
    rescue RestClient::Exception => e
      log "[MOL STRUCT CREATION];#{to_json()};#{e}"
    end
  end
  
  def update( mol_struct_hash )
    @id = mol_struct_hash['id']
    
    unless self.eql? mol_struct_hash
      begin
        response = request( 'PUT', "alleles/#{@id}.json", to_json() )
      rescue RestClient::RequestFailed => e
        if response
          log "[MOL STRUCT UPDATE];#{JSON.parse(response)}\n"
        else
          log "[MOL STRUCT UPDATE];#{to_json()};#{e.http_body}\n"
        end
      rescue RestClient::ServerBrokeConnection
        log "[MOL STRUCT UPDATE];#{to_json()};The server broke the connection prior to the request completing."
      rescue RestClient::RequestTimeout
        log "[MOL STRUCT UPDATE];#{to_json()};Request timed out"
      rescue RestClient::Exception => e
        log "[MOL STRUCT UPDATE];#{to_json()};#{e}"
      end
    end
  end
  
  def push_to_idcc
    existing_mol_struct = 
    MolecularStructure.search(
      @mgi_accession_id, @design_id, 
      @cassette, @backbone, 
      @targeted_trap
    )
    existing_mol_struct.nil? ? create() : update( existing_mol_struct )
  end
end

class TargetingVector
  attr_accessor :id, :pipeline_id, :molecular_structure_id
  attr_accessor :ikmc_project_id, :intermediate_vector, :name
  
  def initialize( args )
    args.each_pair do | key, value |
      self.send("#{key}=", value) if self.respond_to?("#{key}=")
    end
    return self
  end
  
  def eql?( args )
    args.each_pair do |key, value|
      next unless self.instance_variable_defined? "@#{key}"
      return false if self.instance_variable_get("@#{key}") != value
    end
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
  
  def self.get_sql_query_htgt
    query =
    """
    SELECT DISTINCT
      project.project_id,
      ws.pcs_plate_name || '_' || ws.pcs_well_name as intermediate_vector,
      ws.pgdgr_plate_name || '_' || ws.pgdgr_well_name as targeting_vector,
      mgi_gene.mgi_accession_id,
      project.design_id,
      project.cassette,
      project.backbone,
      is_eucomm,
      is_komp_csd,
      is_norcomm
    FROM
      project
      JOIN project_status ON
        project_status.project_status_id = project.project_status_id
        AND project_status.order_by >= 75
      JOIN well_summary_by_di ws ON ws.project_id = project.project_id
      JOIN mgi_gene              ON mgi_gene.mgi_gene_id = project.mgi_gene_id
    WHERE
      (
        project.is_eucomm = 1
        OR project.is_komp_csd = 1
        OR project.is_norcomm = 1
      )
      AND pgdgr_distribute = 'yes'
      AND pgdgr_well_name IS NOT NULL
    ORDER BY mgi_gene.mgi_accession_id
    """
  end
  
  def self.create_or_update
    query = TargetingVector.get_sql_query_htgt()
    begin
      puts "Querying HTGT..."
      cursor = @@ora_dbh.exec( query )
      puts "Done."
    rescue
      log "[TARG VEC SQL];#{query}"
      raise
    end
    
    cursor.fetch do |fetch_row|
      project_id        = fetch_row[0]
      int_vec_name      = fetch_row[1]
      targ_vec_name     = fetch_row[2]
      mgi_accession_id  = fetch_row[3]
      design_id         = fetch_row[4]
      cassette          = fetch_row[5]
      backbone          = fetch_row[6]
      
      design = Design.get( design_id )
      if design.nil?
        log "[TARG VEC SKIP] Could not find design #{design_id}"
        next
      end
      
      unless design.is_valid
        log "[TARG VEC SKIP] Design #{design_id} is invalid"
        next
      end
      
      unless @@changed_projects.include? project_id
        log "[TARG VEC SKIP] Project #{project_id} has not changed"
        next
      end
      
      # Get pipeline ID
      pipeline_id = 
      if fetch_row[7] == 1      then Pipeline.get_id_from( 'EUCOMM' )
      elsif fetch_row[8] == 1   then Pipeline.get_id_from( 'KOMP-CSD' )
      elsif fetch_row[9] == 1   then Pipeline.get_id_from( 'NorCOMM' )
      end
      raise "Pipeline can't be null" if pipeline_id.nil?
      
      # Get molecular structure
      begin
        mol_struct = MolecularStructure.find( mgi_accession_id, design_id, cassette, backbone, false )
      rescue Exception => e
        log "[TARG VEC];#{targ_vec_name};#{e}"
        next
      end
      
      targ_vec = TargetingVector.new({
        :molecular_structure_id => mol_struct.id,
        :pipeline_id            => pipeline_id,
        :ikmc_project_id        => project_id,
        :intermediate_vector    => int_vec_name,
        :name                   => targ_vec_name
      })
      
      targ_vec.push_to_idcc()
      next unless targ_vec.id
      push_to_cache( targ_vec )
    end
    
    TargetingVector.delete_obsoletes()
  end
  
  def self.delete_obsoletes
    page = 1
    while not page.nil?
      response = request( 'GET', "targeting_vectors.json?page=#{page}" )
      targ_vec_list = JSON.parse( response )
      
      if targ_vec_list.length > 0
        targ_vec_list.each do |targ_vec_hash|
          found = 
          @@targ_vec_cache.values.any? do |targ_vec|
            targ_vec.name == targ_vec_hash['name']
          end
          
          if not found
            request( 'DELETE', "targeting_vectors/#{targ_vec_hash['id']}" )
          end
        end
        page += 1
      else
        page = nil
      end
    end
  end
  
  def self.push_to_cache( targ_vec )
    @@targ_vec_cache[targ_vec.id] = targ_vec
  end
  
  def self.flush_cache
    @@targ_vec_cache = nil
  end
  
  def self.find( name, ikmc_project_id )
    # Search in cache
    @@targ_vec_cache.each_pair do |id, targ_vec|
      if targ_vec.name == name and targ_vec.ikmc_project_id == ikmc_project_id
        return targ_vec
      end
    end
    
    # Search through webservice
    targ_vec = search( name, ikmc_project_id )
    return TargetingVector.new( targ_vec ) unless targ_vec.nil?
    
    raise "Can't find targeting vector #{name}"
  end
  
  def self.search( name, ikmc_project_id )
    params = "name=#{name}&ikmc_project_id=#{ikmc_project_id}"
    
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
    @id = targ_vec_hash['id']
    
    unless self.eql? targ_vec_hash
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
    existing_targ_vec = TargetingVector.search( @name, @ikmc_project_id )
    existing_targ_vec.nil? ? create() : update( existing_targ_vec )
  end
end

class EsCell
  attr_accessor :id, :molecular_structure_id, :targeting_vector_id
  attr_accessor :name, :parental_cell_line, :allele_symbol_superscript
  
  def initialize( args )
    @molecular_structure_id, @targeting_vector_id = nil, nil
    args.each_pair do | key, value |
      self.send("#{key}=", value) if self.respond_to?("#{key}=")
    end
    return self
  end
  
  def eql?( args )
    args.each_pair do |key, value|
      next unless self.instance_variable_defined? "@#{key}"
      return false if self.instance_variable_get("@#{key}") != value
    end
  end
  
  def to_json
    JSON.generate({ 
      'es_cell' => {
        'name'                      => @name,
        'parental_cell_line'        => @parental_cell_line,
        'allele_symbol_superscript' => @allele_symbol_superscript,
        'molecular_structure_id'    => @molecular_structure_id,
        'targeting_vector_id'       => @targeting_vector_id
      }
    })
  end
  
  def self.format_allele_symbol_superscript( allele_name )
    rxp_matches = /<sup>(tm\d.*)<\/sup>/.match( allele_name )
    return rxp_matches[1] if rxp_matches
  end
  
  def self.format_parental_cell_line( parental_cell_line )
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
  
  def self.get_sql_query_htgt
    """
    SELECT DISTINCT
      ws.epd_well_name,
      ws.es_cell_line,
      ws.allele_name,
      project.project_id,
      ws.pgdgr_plate_name || '_' || ws.pgdgr_well_name,
      mgi_gene.mgi_accession_id,
      project.design_id,
      project.cassette,
      project.backbone,
      ws.targeted_trap
    FROM
      project
      JOIN well_summary_by_di ws ON ws.project_id = project.project_id
      JOIN mgi_gene              ON mgi_gene.mgi_gene_id = project.mgi_gene_id
    WHERE
      ws.epd_well_name IS NOT NULL
      AND ws.pgdgr_well_name IS NOT NULL
      AND (ws.targeted_trap = 'yes' OR ws.epd_distribute = 'yes')
    ORDER BY mgi_gene.mgi_accession_id, project.design_id, project.project_id
    """
  end
  
  def self.create_or_update
    begin
      puts "Querying HTGT..."
      cursor = @@ora_dbh.exec( get_sql_query_htgt )
      puts "Done."
    rescue
      log "[ES CELL SQL];#{get_sql_query_htgt}"
      raise
    end
    
    cursor.fetch do |fetch_row|
      epd_well_name     = fetch_row[0]
      es_cell_line      = fetch_row[1]
      allele_name       = fetch_row[2]
      project_id        = fetch_row[3]
      targ_vec_name     = fetch_row[4]
      mgi_accession_id  = fetch_row[5]
      design_id         = fetch_row[6]
      cassette          = fetch_row[7]
      backbone          = fetch_row[8]
      targeted_trap     = fetch_row[9] == 'yes'
      
      design = Design.get( design_id )
      next if design.nil?
      next unless design.is_valid
      next unless @@changed_projects.include? project_id
      
      begin
        mol_struct = MolecularStructure.find( mgi_accession_id, design_id, cassette, backbone, targeted_trap )
        targ_vec = TargetingVector.find( targ_vec_name, project_id )
      rescue Exception => e
        log "[ES CELL];#{e}"
        next
      end
      
      es_cell = EsCell.new({
        :molecular_structure_id     => mol_struct.id,
        :targeting_vector_id        => targ_vec.id,
        :name                       => epd_well_name,
        :parental_cell_line         => format_parental_cell_line( es_cell_line ),
        :allele_symbol_superscript  => format_allele_symbol_superscript( allele_name )
      })
      
      es_cell.push_to_idcc()
      next unless es_cell.id
      es_cell.push_to_cache()
    end
    TargetingVector.flush_cache()
    EsCell.delete_obsoletes()
    EsCell.flush_cache()
  end
  
  def self.delete_obsoletes
    page = 1
    while not page.nil?
      response = request( 'GET', "es_cells.json?page=#{page}" )
      es_cell_list = JSON.parse( response )
      
      if es_cell_list.length > 0
        es_cell_list.each do |es_cell_hash|
          found = 
          @@es_cell_cache.values.any? do |es_cell_name|
            es_cell_name == es_cell_hash['name']
          end
          
          if not found
            request( 'DELETE', "es_cells/#{es_cell_hash['id']}" )
          end
        end
        page += 1
      else
        page = nil
      end
    end
  end
  
  def self.push_to_cache( es_cell )
    @@es_cell_cache[es_cell.id] = es_cell.name
  end
  
  def self.flush_cache
    @@es_cell_cache = nil
  end
  
  def push_to_idcc
    existing_es_cell = search()
    existing_es_cell.nil? ? create() : update( existing_es_cell )
  end
  
  def search
    begin
      response = request( 'GET', "es_cells.json?name=#{@name}" )
      json_response = JSON.parse( response )
      return json_response[0] if json_response.length > 0
    rescue RestClient::ResourceNotFound
      return nil
    end
  end
  
  def create
    begin
      response = request( 'POST', 'es_cells.json', to_json() )
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
  
  def update( es_cell_hash )
    @id = es_cell_hash['id']
    unless self.eql? es_cell_hash
      begin
        response = request( 'PUT', "es_cells/#{@id}.json", to_json() )
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
end

class GenbankFile
  attr_accessor :id, :molecular_structure_id, :targeting_vector, :escell_clone
  
  def initialize( args )
    @molecular_structure_id = args[:mol_struct_id]
    
    design_id = args[:design_id]
    cassette, backbone = args[:cassette], args[:backbone]
    
    # Targeting vector file
    url = GENBANK_URL + "?design_id=#{design_id}&cassette=#{cassette}&backbone=#{backbone}"
    @targeting_vector = RestClient::get( url ) rescue ''
    
    # ES Cell clone file
    url = GENBANK_URL + "?design_id=#{design_id}&cassette=#{cassette}"
    url += "&targeted_trap=1" if args[:targeted_trap]
    @escell_clone = RestClient::get( url ) rescue ''
    return self
  end
  
  def to_json
    JSON.generate({
      'genbank_file' => {
        'molecular_structure_id' => @molecular_structure_id,
        'targeting_vector'       => @targeting_vector,
        'escell_clone'           => @escell_clone
      }
    })
  end
  
  def eql?( genbank_file_hash )
    if @targeting_vector == genbank_file_hash['targeting_vector'] \
    and @escell_clone == genbank_file_hash['escell_clone']
      return true
    else
      return false
    end
  end
  
  def create
    begin
      request( 'POST', 'genbank_files.json', to_json() )
    rescue RestClient::RequestFailed => e
      log "[GENBANK FILE CREATION];#{to_json()};#{e.http_body}"
    rescue RestClient::ServerBrokeConnection
      log "[GENBANK FILE CREATION];#{to_json()};The server broke the connection prior to the request completing."
    rescue RestClient::RequestTimeout
      log "[GENBANK FILE CREATION];#{to_json()};Request timed out"
    rescue RestClient::Exception => e
      log "[GENBANK FILE CREATION];#{to_json()};#{e}"
    end
  end
  
  def update( genbank_file_hash )
    @id = genbank_file_hash['id']
    unless self.eql? genbank_file_hash
      begin
        request( 'PUT', "genbank_files/#{@id}.json", to_json() )
      rescue RestClient::RequestFailed => e
        log "[GENBANK FILE UPDATE];#{to_json()};#{e.http_body}"
      rescue RestClient::ServerBrokeConnection
        log "[GENBANK FILE UPDATE];#{to_json()};The server broke the connection prior to the request completing."
      rescue RestClient::RequestTimeout
        log "[GENBANK FILE UPDATE];#{to_json()};Request timed out"
      rescue RestClient::Exception => e
        log "[GENBANK FILE UPDATE];#{to_json()};#{e}"
      end
    end
  end
  
  def self.update_all
    page = 1
    while not page.nil?
      response = request( 'GET', "alleles.json?page=#{page}" )
      mol_struct_list = JSON.parse( response )
      
      if mol_struct_list.length > 0
        mol_struct_list.each do |mol_struct_hash|
          genbank_file = GenbankFile.new({
            :mol_struct_id  => mol_struct_hash['id'],
            :design_id      => mol_struct_hash['project_design_id'],
            :cassette       => mol_struct_hash['cassette'],
            :backbone       => mol_struct_hash['backbone'],
            :targeted_trap  => mol_struct_hash['loxp_start'].nil?
          })
          
          # CREATE or UPDATE Genbank File into IDCC
          if mol_struct_hash.key? 'genbank_file'
            genbank_file.update( mol_struct_hash['genbank_file'] )
          else
            genbank_file.create
          end
        end
        page += 1
      else
        page = nil
      end
    end
  end
  
  def self.create_or_update
    if @@mol_struct_cache.empty?
      GenbankFile.update_all()
    else
      @@mol_struct_cache.each_pair do |mol_struct_id, mol_struct|
        genbank_file = GenbankFile.new({
          :mol_struct_id  => mol_struct.id,
          :design_id      => mol_struct.project_design_id,
          :cassette       => mol_struct.cassette,
          :backbone       => mol_struct.backbone,
          :targeted_trap  => mol_struct.targeted_trap
        })
        
        response = request( 'GET', "genbank_files.json?molecular_structure_id=#{mol_struct.id}" )
        genbank_file_list = JSON.parse( response )
        genbank_file_hash = genbank_file_list.length > 0 ? genbank_file_list[0] : nil
        
        genbank_file_hash.nil? ? create() : update( genbank_file_hash )
      end
    end
  end
end


##
##    Helpers
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
  f << "[#{Time.now.strftime('%d/%m/%Y - %H:%M:%S')}] #{message}\n"
  f.close()
  puts "#{message}\n" if @@debug
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

def report
  errors_file = File.open "#{TODAY}/errors.txt"
  send_to = REPORT_TO.collect { |name, email| "#{name} <#{email}>" }.join(', ')
  
  email = <<-END_OF_MESSAGE
From: I-DCC Loading Script <#{REPORT_FROM}>
Subject: #{REPORT_SUBJECT}
To: #{send_to}

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

@@design_cache, @@mol_struct_cache, @@targ_vec_cache = {}, {}, {}

def run
  system("rm -rf #{@@log_dir}/#{TODAY}")
  system("mkdir -p #{@@log_dir}/#{TODAY}")
  Dir.chdir(@@log_dir)
  
  if @@skip_mol_struct and @@skip_targ_vec and @@skip_es_cell
    puts "-- Loading Genbank Files only --"
    GenbankFile.create_or_update() unless @@skip_genbank_files
  else
    puts "-- Loading pipelines --"
    Pipeline.get_or_create()
  
    puts "\n-- Retrieving designs --"
    Design.retrieve_from_htgt()
  
    puts "\n-- Retrieving new and updated projects --"
    @@changed_projects = get_changed_projects()
  
    unless @@changed_projects.empty?
      puts "\n-- Update IDCC --"
      MolecularStructure.create_or_update()   unless @@skip_mol_struct
      GenbankFile.create_or_update()          unless @@skip_genbank_files
      TargetingVector.create_or_update()      unless @@skip_targ_vec
      EsCell.create_or_update()               unless @@skip_es_cell
    else
      puts "Nothing has changed since the previous run!"
    end
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
