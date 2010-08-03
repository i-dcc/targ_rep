
require 'rubygems'
require 'biomart'
require 'parallel'
require 'httparty'

module DataCheckHelpers
  @@htgt_targ     = Biomart::Dataset.new( 'http://www.sanger.ac.uk/htgt/biomart', { :name => 'htgt_targ' } )
  @@idcc_targ_rep = Biomart::Dataset.new( 'http://www.i-dcc.org/biomart', { :name => 'idcc_targ_rep' } )
  
  # Function to search the htgt_targ mart and return a list of 
  # all of the distributable KOMP-CSD/EUCOMM products according 
  # to HTGT...
  def htgt_targ_get_all_distributable_products
    dist_products = {}

    ['is_komp_csd','is_eucomm'].each do |project_filter|
      puts "[htgt_targ] - requesting data for #{project_filter} projects..."
      data = @@htgt_targ.search(
        :filters => { project_filter => '1' },
        :attributes => [
          'mgi_accession_id',
          'ikmc_project_id',
          'design_id',
          'intvec_plate',
          'intvec_well',
          'intvec_distribute',
          'targvec_plate',
          'targvec_well',
          'targvec_distribute',
          'cassette',
          'backbone',
          'escell_clone',
          'escell_distribute',
          'targeted_trap'
        ]
      )
      
      # data = ""
      # File.open("tmp/htgt_targ_#{project_filter}.marshal",'r').each_line { |line| data << line }
      # data = Marshal.load(data)
      
      cache_file = File.open("tmp/htgt_targ_#{project_filter}.marshal",'w')
      cache_file.write( Marshal.dump(data) )
      cache_file.close
      
      datapos = extract_header_positions( data[:headers] )
      
      puts "[htgt_targ] - processing #{data[:data].size} rows of data for '#{project_filter}' projects..."
      data[:data].each do |result|
        distributable = nil

        if result[datapos[:escell_distribute]] == 'yes' or result[datapos[:targeted_trap]] == 'yes'
          distributable = [:esc,:tv,:iv]
        elsif result[datapos[:targvec_distribute]] == 'yes'
          distributable = [:tv,:iv]
        end

        unless distributable.nil?
          result_data = dist_products[ result[datapos[:ikmc_project_id]].to_i ]

          if result_data.nil?
            result_data = {
              :mgi_accession_id => result[datapos[:mgi_accession_id]].to_s,
              :design_id        => result[datapos[:design_id]].to_s,
              :iv               => [],
              :tv               => [],
              :esc              => []
            }

            result_data[:project] = case project_filter
            when 'is_komp_csd' then 'KOMP-CSD'
            when 'is_eucomm'   then 'EUCOMM'
            end
          end

          if result_data[:cassette].nil? and result[datapos[:cassette]] != nil
            result_data[:cassette] = result[datapos[:cassette]].to_s
          end

          if result_data[:backbone].nil? and result[datapos[:backbone]] != nil
            result_data[:backbone] = result[datapos[:backbone]].to_s
          end

          result_data[:esc].push( result[datapos[:escell_clone]].to_s ) if distributable.include?(:esc)
          
          if distributable.include?(:tv)
            unless result[datapos[:targvec_plate]].nil? and result[datapos[:targvec_well]].nil?
              result_data[:tv].push( "#{result[datapos[:targvec_plate]].to_s}_#{result[datapos[:targvec_well]].to_s}" )
            end
          end
          
          if distributable.include?(:iv)
            unless result[datapos[:intvec_plate]].nil? and result[datapos[:intvec_well]].nil?
              result_data[:iv].push( "#{result[datapos[:intvec_plate]].to_s}_#{result[datapos[:intvec_well]].to_s}" )                
            end
          end

          result_data[:tv].uniq!
          result_data[:iv].uniq!

          dist_products[ result[datapos[:ikmc_project_id]].to_i ] = result_data
        end
      end

      puts "[htgt_targ] - done processing #{project_filter} projects..."
    end

    return dist_products
  end
  
  # Function to search the idcc_targ_rep mart and return details 
  # for all the KOMP-CSD/EUCOMM products within...
  def idcc_targ_rep_get_all_products
    dist_products = {}

    ['KOMP-CSD','EUCOMM'].each do |project_filter|
      puts "[idcc_targ_rep] - requesting data for '#{project_filter}' projects..."
      data = @@idcc_targ_rep.search(
        :filters => { 'pipeline' => project_filter },
        :attributes => [
          'pipeline',
          'ikmc_project_id',
          'mgi_accession_id',
          'design_id',
          'intermediate_vector',
          'targeting_vector',
          'cassette',
          'backbone',
          'escell_clone'
        ]
      )
      
      # data = ""
      # File.open("tmp/idcc_targ_rep_#{project_filter}.marshal",'r').each_line { |line| data << line }
      # data = Marshal.load(data)
      
      cache_file = File.open("tmp/idcc_targ_rep_#{project_filter}.marshal",'w')
      cache_file.write( Marshal.dump(data) )
      cache_file.close
      
      datapos = extract_header_positions( data[:headers] )
      
      puts "[idcc_targ_rep] - processing #{data[:data].size} rows of data for '#{project_filter}' projects..."

      data[:data].each do |result|
        result_data = dist_products[ result[datapos[:ikmc_project_id]].to_i ]
        
        if result_data.nil?
          result_data = {
            :mgi_accession_id => result[datapos[:mgi_accession_id]].to_s,
            :project          => result[datapos[:pipeline]].to_s,
            :design_id        => result[datapos[:design_id]].to_s,
            :cassette         => result[datapos[:cassette]].to_s,
            :backbone         => result[datapos[:backbone]].to_s,
            :iv               => [],
            :tv               => [],
            :esc              => []
          }
        end

        result_data[:esc].push( result[datapos[:escell_clone]].to_s ) unless result[datapos[:escell_clone]].nil?
        result_data[:tv].push( result[datapos[:targeting_vector]].to_s ) unless result[datapos[:targeting_vector]].nil?
        result_data[:iv].push( result[datapos[:intermediate_vector]].to_s ) unless result[datapos[:intermediate_vector]].nil?

        result_data[:tv].uniq!
        result_data[:iv].uniq!

        dist_products[ result[datapos[:ikmc_project_id]].to_i ] = result_data
      end
      
      puts "[idcc_targ_rep] - done processing #{project_filter} projects..."
    end
    
    return dist_products
  end
  
  # Function to compare data from HTGT to the targ_rep and return 
  # a hash of the projects/products the are missing from the targ_rep.
  def find_htgt_to_targ_rep_discrepancies
    htgt_products = {}
    idcc_products = {}
    
    threads = []
    threads << Thread.new() { htgt_products = htgt_targ_get_all_distributable_products }
    threads << Thread.new() { idcc_products = idcc_targ_rep_get_all_products }
    threads.each { |thread| thread.join }
    
    # Work through each of the HTGT projects and remove data 
    # that is in the targ_rep (leaving only the misses)...
    puts "[find_htgt_to_targ_rep_discrepancies] - extracting discrepancies..."
    htgt_products.keys.each do |ikmc_project_id|
      htgt_data = htgt_products[ikmc_project_id]
      idcc_data = idcc_products[ikmc_project_id]
      
      unless idcc_data.nil?
        # Remove the duplicates...
        htgt_data[:esc] = htgt_data[:esc] - idcc_data[:esc] unless htgt_data[:esc].empty?
        htgt_data[:tv]  = htgt_data[:tv] - idcc_data[:tv]   unless htgt_data[:tv].empty?
        htgt_data[:iv]  = htgt_data[:iv] - idcc_data[:iv]   unless htgt_data[:iv].empty?
      end
      
      htgt_products[ikmc_project_id] = htgt_data
    end
    
    # Delete the projects that are clean in the targ_rep
    htgt_products.delete_if do |key,value|
      value[:esc].empty? and value[:tv].empty? and value[:iv].empty?
    end
    
    return htgt_products
  end
  
  # Biomart data return helper - works out the positions of each 
  # attribute within the data arrays without the overhead of 
  # converting the arrays to hashes.
  def extract_header_positions( headers )
    datapos = {}
    headers.each_index { |index| datapos[ headers[index].to_sym ] = index }
    return datapos
  end
  
  # Function to get details on ALL the alleles in the targ_rep.
  def get_allele_ids_with_products
    alleles = {}
    
    puts "[idcc_targ_rep] - requesting data for all alleles..."
    data = @@idcc_targ_rep.search(
      :filters => {},
      :attributes => [
        'pipeline',
        'ikmc_project_id',
        'mgi_accession_id',
        'cassette',
        'backbone',
        'targeting_vector',
        'escell_clone',
        'allele_id'
      ]
    )
    
    # data = ""
    # File.open("tmp/idcc_targ_rep_allele_ids_with_products.marshal",'r').each_line { |line| data << line }
    # data = Marshal.load(data)
    
    cache_file = File.open("tmp/idcc_targ_rep_allele_ids_with_products.marshal",'w')
    cache_file.write( Marshal.dump(data) )
    cache_file.close
    
    datapos = extract_header_positions( data[:headers] )
    
    puts "[idcc_targ_rep] - processing #{data[:data].size} rows of data..."
    data[:data].each do |result|
      result_data = alleles[ result[datapos[:allele_id]].to_i ]
      
      if result_data.nil?
        result_data = {
          :mgi_accession_id => result[datapos[:mgi_accession_id]].to_s,
          :project          => result[datapos[:pipeline]].to_s,
          :cassette         => result[datapos[:cassette]].to_s,
          :backbone         => result[datapos[:backbone]].to_s,
          :tv               => false,
          :esc              => false
        }
      end
      
      result_data[:tv]  = true unless result[datapos[:targeting_vector]].nil?
      result_data[:esc] = true unless result[datapos[:escell_clone]].nil?
      
      alleles[ result[datapos[:allele_id]].to_i ] = result_data
    end
    
    puts "[idcc_targ_rep] - done processing data..."
    
    return alleles
  end
  
  # Function to query the production targ_rep and report whether an 
  # allele or vector image was successfully returned.  Returns a hash 
  # of alleles which gave an error for either request.
  def check_image_drawing_coverage
    alleles                 = get_allele_ids_with_products
    alleles_with_bad_images = {}
    req_count               = 0
    
    # Perform a GET request for vector and allele images 
    # (if we have any vectors or alleles present) and store 
    # the results if we get a fail...
    #
    # Do the requests in parallel (using the 'parallel' gem)
    puts "[check_image_drawing_coverage] - running requests for #{alleles.keys.size} alleles..."
    puts "[check_image_drawing_coverage] - this may take some time..."
    puts "[check_image_drawing_coverage] - allele: 0 / #{alleles.keys.size}"
    Parallel.each( alleles.keys, :in_threads => 10 ) do |allele_id|
      allele = alleles[allele_id]
      
      if allele[:tv]
        vector_res = HTTParty.get("#{TARG_REP_URL}/alleles/#{allele_id}/vector-image")
        allele[:vector_img] = vector_res.code
        #puts "[check_image_drawing_coverage] - #{TARG_REP_URL}/alleles/#{allele_id}/vector-image : #{vector_res.code}"
      end
      
      if allele[:esc]
        allele_res = HTTParty.get("#{TARG_REP_URL}/alleles/#{allele_id}/allele-image")
        allele[:allele_img] = allele_res.code
        #puts "[check_image_drawing_coverage] - #{TARG_REP_URL}/alleles/#{allele_id}/allele-image : #{allele_res.code}"
      end
      
      if allele[:allele_img] != 200 or allele[:vector_img] != 200
        alleles_with_bad_images[allele_id] = alleles[allele_id]
      end
      
      req_count = req_count + 1
      if req_count % 100 == 0
        puts "[check_image_drawing_coverage] - allele: #{req_count} / #{alleles.keys.size}"
      end
      
      sleep(1)
    end
    
    # alleles_with_bad_images = ""
    # File.open("tmp/alleles_with_bad_images.marshal",'r').each_line { |line| alleles_with_bad_images << line }
    # alleles_with_bad_images = Marshal.load(data)
    
    cache_file = File.open("tmp/alleles_with_bad_images.marshal",'w')
    cache_file.write( Marshal.dump(alleles_with_bad_images) )
    cache_file.close
    
    return alleles_with_bad_images
  end
  
end