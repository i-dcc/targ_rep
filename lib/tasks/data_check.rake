
require 'lib/data_check_helpers.rb'
include DataCheckHelpers

namespace :targ_rep do
  
  desc "Build a cache of the discrepacies between HTGT and the targ_rep"
  task :htgt_discrepacies_cache_build do
    discrepancies = find_htgt_to_targ_rep_discrepancies
    
    cache_file = File.open('tmp/htgt_discrepacies.marshal','w')
    cache_file.write( Marshal.dump(discrepancies) )
    cache_file.close
  end
  
  @discrepancies = ""
  
  task :htgt_discrepacies_report_helper do
    cache_file = File.open('tmp/htgt_discrepacies.marshal','r')
    cache_file.each_line { |line| @discrepancies << line }
    cache_file.close
    
    @discrepancies = Marshal.load(@discrepancies)
  end
  
  desc "Generate a report showing all the missing ES Cells (in targ_rep) from HTGT"
  task :htgt_discrepacies_esc_report => [:htgt_discrepacies_report_helper] do
    CSV.open('public/downloads/htgt_discrepacies_esc_report.csv','wb') do |csv|
      csv << [
        "Pipeline",
        "MGI Accession ID",
        "IKMC Project ID",
        "Design ID",
        "Cassette",
        "Backbone",
        "ES Cell Clone"
      ]
      
      @discrepancies.each do |ikmc_project,data|
        data[:esc].each do |esc|
          csv << [
            data[:project],
            data[:mgi_accession_id],
            ikmc_project,
            data[:design_id],
            data[:cassette],
            data[:backbone],
            esc
          ]
        end
      end
    end
  end
  
  desc "Generate a report showing all the missing Targeting Vectors (in targ_rep) from HTGT"
  task :htgt_discrepacies_tv_report => [:htgt_discrepacies_report_helper] do
    
  end
  
  desc "Generate a report showing all the missing Intermediate Vectors (in targ_rep) from HTGT"
  task :htgt_discrepacies_iv_report => [:htgt_discrepacies_report_helper] do
    
  end
  
  
  
end