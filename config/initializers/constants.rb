GENBANK_RECOMBINATION_PATH = case Rails.env
when 'production' then
  ''
else
  'test/lib/'
end
