GENBANK_RECOMBINATION_SCRIPT_PATH = case Rails.env
when 'production' then
  'recombinate_sequence.pl'
else
  'test/lib/recombinate_sequence.pl'
end
