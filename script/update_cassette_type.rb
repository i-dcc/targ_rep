# A mapping of the available cassette names to types
cassette_types = {
  "L1L2_gt0"              => "Promotorless",
  "L1L2_gt1"              => "Promotorless",
  "L1L2_gt2"              => "Promotorless",
  "L1L2_gtk"              => "Promotorless",
  "L1L2_st0"              => "Promotorless",
  "L1L2_st1"              => "Promotorless",
  "L1L2_st2"              => "Promotorless",
  "L1L2_NTARU-0"          => "Promotorless",
  "L1L2_NTARU-1"          => "Promotorless",
  "L1L2_NTARU-2"          => "Promotorless",
  "L1L2_NTARU-K"          => "Promotorless",
  "L1L2_hubi_P"           => "Promotor Driven",
  "L1L2_Bact_P"           => "Promotor Driven",
  "L1L2_GOHANU"           => "Promotor Driven",
  "TM-ZEN-UB1"            => "Promotor Driven",
  "L1L2_6XOspnEnh_Bact_P" => "Promotor Driven",
  "L1L2_Pgk_P"            => "Promotor Driven",
  "L1L2_Pgk_PM"           => "Promotor Driven",
  "L1L2_Del_BactPneo_FFL" => "Promotor Driven",
  "ZEN-Ub1"               => "Promotor Driven",
  "ZEN-UB1.GB"            => "Promotor Driven",
  "PGK_EM7_PuDtk_bGHpA"   => "Promotor Driven",
  "pL1L2_PAT_B0"          => "Promotor Driven",
}

# Update the cassette_type for the existing alleles
Allele.all.each do |allele|
  allele.cassette_type = cassette_types[allele.cassette]
  begin
    allele.save!
  rescue RecordNotSaved
    puts "Could not save data for allele #{allele.id}"
    next
  end
  puts "Set cassette_type for allele #{allele.id} to '#{allele.cassette_type}'"
end
