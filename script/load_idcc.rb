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

# TODO: Remove "production" and "test" options when pushing live
opts = GetoptLong.new(
  [ '--help',                   '-h',   GetoptLong::NO_ARGUMENT ],
  [ '--production',             '-p',   GetoptLong::NO_ARGUMENT ],
  [ '--test',                   '-t',   GetoptLong::NO_ARGUMENT ],
  [ '--no_genbank_files',               GetoptLong::NO_ARGUMENT ],
  [ '--no_report',                      GetoptLong::NO_ARGUMENT ],
  [ '--debug',                          GetoptLong::NO_ARGUMENT ]
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
      @@ora_dbh   = OCI8.new(ORA_USER, ORA_PASS, 'migt_ha.world')
      @@log_dir   = 'htgt_load'
    when '--debug'
      @@debug = true
    when '--no_genbank_files'
      @@no_genbank_files = true
    when '--no_report'
      @@no_report = true
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
    @is_valid = true
    @@instances.push(design)
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
      
      # 2 options:
      # 1- Fetched design_id equals previously fetched design_id
      # 2- Fetched design_id is new
      
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
          break unless design.is_valid?
          
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
          break unless design.is_valid?
          
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
    return @is_valid == true
  end
end

class Allele < IdccObject
  ATTRIBUTES = [
    :allele_id, :pipeline_id, :design_id, :mgi_accession_id, :chromosome, 
    :strand, :allele_symbol_superscript, :design_type, :design_subtype, 
    :subtype_description, :cassette, :backbone, :ikmc_project_id, 
    :intermediate_vector, :targeting_vector, :parental_cell_line,
    :targeting_vector_genbank_file, :escell_clone_genbank_file,
    :cassette_start, :cassette_end, :loxp_start, :loxp_end, 
    :homology_arm_start, :homology_arm_end, :products, :targeted_trap
  ].freeze
  ATTRIBUTES.each { |attr| attr_accessor attr }
  NOT_DUMPED = [:allele_id, :design_id, :products, :targeted_trap]
  
  def initialize( args = nil )
    allele = super(args)
    @products = []
    allele
  end
  
  @@changed_project_ids = []
  def self.changed_project_ids
    @@changed_project_ids
  end
  
  # Return true or false whether Allele differs from given hash
  def has_changed( allele_hash )
    not_checked = NOT_DUMPED + [:pipeline_id, :targeting_vector_genbank_file, :escell_clone_genbank_file]
    
    (ATTRIBUTES - not_checked).each do |attr|
      self_value  = self.instance_variable_get "@#{attr}"
      other_value = allele_hash[attr.to_s]
      if self_value.to_s != other_value.to_s
        log "[ALLELE CHANGES];#{@allele_id};#{attr};'#{other_value}' -> '#{self_value}'"
        return true
      end
    end
    false
  end
  
  # Will get the project ids to filter on when finding new or udpated alleles
  def self.get_changed_projects
    # 1- Look in project_history table. This table holds added and updated
    #   projects along with a timestamp.
    #   -> Take entries inserted within the last 2 days.
    query =
    """
    SELECT DISTINCT
      project.project_id
    FROM
      project
      JOIN project_history ON (
        project_history.project_id = project.project_id
        AND history_date >= current_date - 2
      )
    """
    @@ora_dbh.exec(query) { |row| @@changed_project_ids.push( row[0] ) }
    
    # 2- Compare today's dump of well_summary_by_di table to yesterday's dump.
    #   -> No timestamp in this table so need to put yesterday's dump in a file
    #      and compare to today's file
    old_file = File.new('previous_epd_dump.txt', 'r') rescue nil
    new_file = File.new('current_epd_dump.txt', 'w+') # Read-write mode

    # Dumping today's data
    query =
    """
    SELECT DISTINCT project_id, epd_well_name
    FROM well_summary_by_di
    WHERE project_id IS NOT NULL AND epd_well_name IS NOT NULL
    ORDER BY project_id, epd_well_name
    """
    @@ora_dbh.exec(query) { |row| new_file << row.join(';') + "\n" }
    
    if old_file.nil?
      system('mv current_epd_dump.txt previous_epd_dump.txt')
      return
    end
    
    # Go to beginning of new_file for reading
    new_file.seek(0)
    
    
    ## Start: helpers
    def self.get_next_line( file )
      return file.readline.chomp.split(';') rescue nil
    end
  
    def self.add_project_id( project_id )
      unless @@changed_project_ids.include? project_id
        @@changed_project_ids.push( project_id )
      end
    end
    ## End: Helpers
    
    
    # Compare old and new files
    finished = false
    new_line = get_next_line( new_file )
    old_line = get_next_line( old_file )
    
    while not finished
      finished = true if new_line.nil? and old_line.nil?
      
      # EOF new_file
      if new_line.nil?
        old_line = get_next_line( old_file )
        add_project_id( old_line[0] ) if old_line
      
      # EOF old_file
      elsif old_line.nil?
        new_line = get_next_line( new_file )
        add_project_id( new_line[0] ) if new_line
      
      elsif new_line == old_line
        new_line = get_next_line(new_file)
        old_line = get_next_line(old_file)
      
      else
        new_project_id = new_line[0]
        old_project_id = old_line[0]
        
        if new_project_id > old_project_id
          add_project_id( old_project_id )
          old_line = get_next_line( old_file )
        
        elsif new_project_id < old_project_id
          add_project_id( new_project_id )
          new_line = get_next_line( new_file )
        
        else
          add_project_id( new_project_id )
          if new_line[1] < old_line[1]
            new_line = get_next_line( new_file )
          else
            old_line = get_next_line( old_file )
          end
        end
      end
    end
    
    system('mv current_epd_dump.txt previous_epd_dump.txt')
  end
  
  def self.idcc_update
    return nil if @@changed_project_ids.length == 0
    
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
    @@changed_project_ids.each do |project_id|
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
    
    #--- Additional conditions are set, let's create the query
    # Conditional and non-conditional alleles are selected in two rows.
    # Alleles with null names are selected so that design is stored.
    query =
    """
    SELECT DISTINCT
      allele_name,
      project.design_id,
      project.backbone,
      project.cassette,
      project.project_id,
      pcs_plate_name || '_' || pcs_well_name as intermediate_vector,
      pgdgr_plate_name || '_' || pgdgr_well_name as targeting_vector,
      es_cell_line,
      ws.targeted_trap,
      mgi_gene.mgi_accession_id,
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
      AND (pgdgr_distribute = 'yes' OR ws.epd_distribute = 'yes')
      AND (pcs_well_name IS NOT NULL OR pgdgr_well_name IS NOT NULL)
      AND ( #{design_filter} )
      AND ( #{project_filter} )
    """
    
    begin
      cursor = @@ora_dbh.exec(query)
    rescue
      log "[ALLELE SQL];#{query}"
      next
    end
    
    cursor.fetch do |fetch_row|
      allele_name           = fetch_row[0]
      design_id             = fetch_row[1]
      backbone              = fetch_row[2]
      cassette              = fetch_row[3]
      ikmc_project_id       = fetch_row[4]
      intermediate_vector   = fetch_row[5]
      targeting_vector      = fetch_row[6]
      parental_cell_line    = fetch_row[7]
      targeted_trap         = fetch_row[8] == 'yes'
      mgi_accession_id      = fetch_row[9]
      is_eucomm             = fetch_row[10] == 1
      is_komp_csd           = fetch_row[11] == 1
      is_norcomm            = fetch_row[12] == 1
      
      #--- First, let's check if allele is valid
      if targeting_vector
        if backbone.nil?
          log "[ALLELE VALIDATION];#{design_id};#{targeting_vector};backbone is missing"
          next
        elsif cassette.nil?
          log "[ALLELE VALIDATION];#{design_id};#{targeting_vector};cassette is missing"
          next
        end
      end
      
      #--- From here, allele is valid, let's compute its values
      design    = Design.get( design_id )
      features  = design.features
      
      #-- Pipeline id
      pipeline_id =
      if is_eucomm then Pipeline.get_id_from('EUCOMM')
      elsif is_komp_csd then Pipeline.get_id_from('KOMP-CSD')
      elsif is_norcomm then Pipeline.get_id_from('NorCOMM')
      else raise "Pipeline unknown"
      end
      
      #-- Allele symbol superscript
      rxp_matches = /<sup>(tm\d[e|a].*)<\/sup>/.match( allele_name )
      allele_symbol_superscript = rxp_matches[1] if rxp_matches
      
      #-- Parental cell line
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
      
      #-- Homology Arm
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
      
      #-- Cassette
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

      #-- LoxP, unless targeted trap
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
      
      # Now that every field is properly formated, let's create the Allele
      allele = Allele.new({
        :pipeline_id                => pipeline_id,
        :allele_symbol_superscript  => allele_symbol_superscript,
        :backbone                   => backbone,
        :cassette                   => cassette,
        :ikmc_project_id            => ikmc_project_id,
        :intermediate_vector        => intermediate_vector,
        :targeting_vector           => targeting_vector,
        :parental_cell_line         => parental_cell_line,
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
        :targeted_trap              => targeted_trap,
        :targeting_vector_genbank_file => nil,
        :escell_clone_genbank_file  => nil
      })
      
      begin
        allele.update_or_create()
        allele.synchronize_products()
      rescue RestClient::ServerBrokeConnection
        log "[ALLELE];#{allele.to_json()};The server broke the connection prior to the request completing. Usually this means it crashed, or sometimes that your network connection was severed before it could complete."
      rescue RestClient::RequestTimeout
        log "[ALLELE];#{allele.to_json()};Request timed out"
      rescue RestClient::Exception => e
        log "[ALLELE];#{allele.to_json()};#{e.http_body}"
      rescue Exception => e
        log "[ALLELE];#{allele.to_json()};#{e}"
      end
    end
  end
  
  def update_or_create
    # Search for an IDCC allele with IKMC project ID and targeting vector
    params = "ikmc_project_id=#{@ikmc_project_id}&targeting_vector=#{@targeting_vector}"
    response = request( 'GET', "alleles.json?#{params}" )
    
    allele_hash = nil
    JSON.parse(response).each do |allele|
      if allele['allele_symbol_superscript'].nil? or allele['allele_symbol_superscript'].empty?
        allele_hash = allele
      elsif allele['allele_symbol_superscript'] == @allele_symbol_superscript
        allele_hash = allele
        break
      end
    end
    
    # CREATE IDCC allele if not found ...
    if allele_hash.nil?
      response = request( 'POST', 'alleles.json', to_json )
      @allele_id = JSON.parse(response)['id']
      
    # ... or UPDATE it - if any change has been made
    else
      @allele_id = allele_hash['id']
      @products  = allele_hash['products']
      if has_changed( allele_hash )
        request( 'PUT', "alleles/#{@allele_id}.json", to_json )
      end
    end

    # Include genbank files if script option is on
    get_genbank_files() unless @@no_genbank_files
  end
  
  def get_genbank_files
    base_params = "?cassette=#{@cassette}&design_id=#{@design_id}"
    
    # Targeting vector
    begin
      params = base_params + "&backbone=#{@backbone}"
      @targeting_vector_genbank_file = request( method = 'GET', url = params, site = GENBANK_URL )
    rescue RestClient::Exception => e
      @targeting_vector_genbank_file = nil
    end
    
    # ES Cell clone
    begin
      base_params += "&targeted_trap=1" if @targeted_trap
      @escell_clone_genbank_file = request( method = 'GET', url = base_params, site = GENBANK_URL )
    rescue RestClient::Exception => e
      @escell_clone_genbank_file = nil
    end
  end
  
  def synchronize_products
    query = 
    """
      SELECT epd_well_name FROM well_summary_by_di
      WHERE
        project_id = #{@ikmc_project_id}
        AND epd_well_name IS NOT NULL
    """
    if @allele_symbol_superscript
      query += 
      """
      AND allele_name LIKE \'%#{@allele_symbol_superscript}%\'
      """
    else
      # If the allele HAS NOT a name, find the products depending on targeting
      # vector but exclude products related to a named allele.
      query +=
      """
      AND pgdgr_plate_name || '_' || pgdgr_well_name = '#{@targeting_vector}'
      AND allele_name IS NULL
      """
    end
    
    htgt_products = []
    @@ora_dbh.exec(query) { |fetch_row| htgt_products.push(fetch_row[0]) }
    
    idcc_products = []
    @products.each { |product| idcc_products.push(product['escell_clone']) }
    
    # 1- Delete product from IDCC if it no longer exists in HTGT
    if (idcc_products - htgt_products).length > 0
      @products.each do |product|
        next if product.empty?
        
        unless htgt_products.include? product['escell_clone']
          begin
            request( 'DELETE', "products/#{product['id']}/" )
          rescue RestClient::Exception => e
            log "[PRODUCT DELETE];#{product['id']};#{e.http_body}"
          end
        end
      end
    end
    
    # 2- Add product to IDCC if it is new in HTGT or move allele association 
    # if product already exist in IDCC
    (htgt_products - idcc_products).each do |escell_clone|
      
      # Search product in IDCC - ie. linked to another allele
      response = request('GET', "products.json?escell_clone=#{escell_clone}")
      product_list = JSON.parse( response )
      product_found = product_list[0] if product_list.size > 0
      
      json = JSON.generate({ 
                'product' => { 
                  'allele_id' => @allele_id, 
                  'escell_clone' => escell_clone 
                }
              })

      # Update or create IDCC product
      begin
        if product_found
          action = "UPDATE"
          request( 'PUT', "products/#{product_found['id']}.json", json )
        else
          action = "CREATION"
          request( 'POST', 'products.json', json )
        end
      rescue RestClient::Exception => e
        log "[PRODUCT #{action}];#{json};#{e.http_body}"
      end
    end
  end
end


#
#   Main script
#

def run
  # Initialize script directory
  system("mkdir -p #{@@log_dir}/#{TODAY}")
  Dir.chdir(@@log_dir)
  
  Pipeline.get_or_create()
  Pipeline.each do |pipeline|
    puts "Pipeline loaded: id #{pipeline.id} name #{pipeline.name}"
  end

  puts "Retrieving designs ..."
  Design.retrieve_from_htgt()
  puts "#{Design.count} designs"

  puts "\nValidating designs ..."
  Design.validation()
  
  puts "\nLogging designs ..."
  Design.log()

  puts "\nRetrieving new and updated projects ..."
  Allele.get_changed_projects()
  if Allele.changed_project_ids.length > 0
    log "Changed projects: #{Allele.changed_project_ids.join(',')}"
    
    puts "\nUpdating alleles ..."
    Allele.idcc_update()
  else
    puts "Nothing has changed since the previous run"
  end  

  unless @@no_report
    puts "\nSending email report"
    report()
  end
end

c = Chrono.new()
c.start()
run()
c.stop()
