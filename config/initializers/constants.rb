if Rails.env == 'production'
  GENBANK_RECOMBINATION_SCRIPT_PATH = 'recombinate_sequence.pl'
else
  script_path = 'test/lib/recombinate_sequence.pl'
  ENV['PATH'].split(':').each do |folder|
    if File.exists?("#{folder}/recombinate_sequence.pl")
      script_path = 'recombinate_sequence.pl'
      break
    end
  end
  GENBANK_RECOMBINATION_SCRIPT_PATH = script_path
end
