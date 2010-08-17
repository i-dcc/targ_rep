
require 'lib/data_check_helpers.rb'
include DataCheckHelpers

def dump_htgt_missing_product_report( discrepancies, report_file, product_type, product_key )
  CSV.open(report_file,'wb') do |csv|
    csv << [
      "Pipeline",
      "MGI Accession ID",
      "IKMC Project ID",
      "Design ID",
      "Cassette",
      "Backbone",
      product_type
    ]
    
    discrepancies.each do |ikmc_project,data|
      data[product_key].each do |prod|
        csv << [
          data[:project],
          data[:mgi_accession_id],
          ikmc_project,
          data[:design_id],
          data[:cassette],
          data[:backbone],
          prod
        ]
      end
    end
  end
end

namespace :targ_rep do
  TARG_REP_URL = 'http://htgt.internal.sanger.ac.uk:4001/targ_rep'
  
  desc "Build a cache of the discrepacies between HTGT and the targ_rep"
  task :htgt_discrepacies_cache_build do
    discrepancies = find_htgt_to_targ_rep_discrepancies
    
    cache_file = File.open('tmp/htgt_discrepancies.marshal','w')
    cache_file.write( Marshal.dump(discrepancies) )
    cache_file.close
  end
  
  @discrepancies = ""
  
  task :htgt_discrepacies_report_helper do
    cache_file = File.open('tmp/htgt_discrepancies.marshal','r')
    cache_file.each_line { |line| @discrepancies << line }
    cache_file.close
    
    @discrepancies = Marshal.load(@discrepancies)
  end
  
  desc "Generate a report showing all the missing ES Cells (in targ_rep) from HTGT"
  task :htgt_discrepacies_esc_report => [:htgt_discrepacies_report_helper] do
    dump_htgt_missing_product_report(
      @discrepancies,
      'public/downloads/htgt_discrepacies_esc_report.csv',
      'ES Cell Clone',
      :esc
    )
  end
  
  desc "Generate a report showing all the missing Targeting Vectors (in targ_rep) from HTGT"
  task :htgt_discrepacies_tv_report => [:htgt_discrepacies_report_helper] do
    dump_htgt_missing_product_report(
      @discrepancies,
      'public/downloads/htgt_discrepacies_tv_report.csv',
      'Targeting Vector',
      :tv
    )
  end
  
  desc "Generate a report showing all the missing Intermediate Vectors (in targ_rep) from HTGT"
  task :htgt_discrepacies_iv_report => [:htgt_discrepacies_report_helper] do
    dump_htgt_missing_product_report(
      @discrepancies,
      'public/downloads/htgt_discrepacies_iv_report.csv',
      'Intermediate Vector',
      :iv
    )
  end
  
  desc "Generate a report showing all of the alleles that throw errors when trying to draw images"
  task :image_drawing_errors do
    bad_alleles = check_image_drawing_coverage
    
    CSV.open('public/downloads/image_drawing_errors.csv','wb') do |csv|
      csv << [
        "Pipeline",
        "MGI Accession ID",
        "Allele ID",
        "Cassette",
        "Backbone",
        "Allele Image Status Code",
        "Allele Image URL",
        "Vector Image Status Code",
        "Vector Image URL"
      ]

      bad_alleles.each do |allele_id,data|
        csv << [
          data[:project],
          data[:mgi_accession_id],
          allele_id,
          data[:cassette],
          data[:backbone],
          data[:allele_img],
          data[:esc] ? "#{TARG_REP_URL}/alleles/#{allele_id}/allele-image" : nil,
          data[:vector_img],
          data[:tv] ? "#{TARG_REP_URL}/alleles/#{allele_id}/vector-image" : nil
        ]
      end
    end
  end
  
end