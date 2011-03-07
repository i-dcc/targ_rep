require "getoptlong"
require "csv"

opts = GetoptLong.new([ '--file',  '-f', GetoptLong::REQUIRED_ARGUMENT ])
file = nil
ids  = []

# Process the options ...
opts.each do |opt, arg|
  case opt
  when '--file' then file = arg
  end
end

# Check if the user specified a file
unless file.nil?
  puts "Processing alleles from file '#{file}'"
  ids = CSV.parse(File.read(file)).flatten.map { |i| i.to_i }
end

# Get the corresponding allele objects
alleles = ids.empty? ? Allele.all : Allele.find(ids)

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
puts "#{alleles.count} alleles to process"
alleles.each do |allele|
  allele.cassette_type = cassette_types[allele.cassette]
  begin
    allele.save!
  rescue RecordNotSaved => error
    puts "Could not save data for allele #{allele.id}: #{error}"
    next
  rescue Exception => error
    puts "Something went wrong for allele #{allele.id}: #{error}"
    next
  end
  puts "Set cassette_type for allele #{allele.id} to '#{allele.cassette_type}'"
end
