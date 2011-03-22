class AddCassetteTypeToAllele < ActiveRecord::Migration
  def self.up
    add_column :alleles, :cassette_type, :string
    
    promotor_driven_cassettes = %w{
      L1L2_6XOspnEnh_Bact_P
      L1L2_Bact_P
      L1L2_Del_BactPneo_FFL
      L1L2_GOHANU
      L1L2_hubi_P
      L1L2_Pgk_P
      L1L2_Pgk_PM
      PGK_EM7_PuDtk_bGHpA
      pL1L2_PAT_B0
      TM-ZEN-UB1
      ZEN-Ub1
      ZEN-UB1.GB
    }
    promotor_driven_cassettes.each do |cassette|
      execute "update alleles set cassette_type = 'Promotor Driven' where cassette = '#{cassette}'"
    end
    
    promotorless_cassettes = %w{
      L1L2_gt0
      L1L2_gt1
      L1L2_gt2
      L1L2_gtk
      L1L2_NTARU-0
      L1L2_NTARU-1
      L1L2_NTARU-2
      L1L2_NTARU-K
      L1L2_st0
      L1L2_st1
      L1L2_st2
    }
    promotorless_cassettes.each do |cassette|
      execute "update alleles set cassette_type = 'Promotorless' where cassette = '#{cassette}'"
    end
  end

  def self.down
    remove_column :alleles, :cassette_type
  end
end