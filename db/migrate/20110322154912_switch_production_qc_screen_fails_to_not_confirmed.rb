class SwitchProductionQcScreenFailsToNotConfirmed < ActiveRecord::Migration
  def self.up
    ['production_qc_five_prime_screen','production_qc_three_prime_screen','production_qc_loxp_screen'].each do |screen|
      execute("update es_cells set #{screen} = 'not confirmed' where #{screen} = 'fail'")
    end
  end

  def self.down
    ['production_qc_five_prime_screen','production_qc_three_prime_screen','production_qc_loxp_screen'].each do |screen|
      execute("update es_cells set #{screen} = 'fail' where #{screen} = 'not confirmed'")
    end
  end
end
