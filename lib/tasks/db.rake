namespace :db do

  ['development', 'staging', 'production'].each do |envname|
    desc "Dump #{envname} DB into db/dump.#{envname}.sql"
    task "#{envname}:dump" do
      config = YAML.load_file("#{Rails.root}/config/database.yml")[envname]
      if ! config
        config = YAML.load_file("#{Rails.root}/config/database.#{envname}.yml")[envname]
      end
      raise "Cannot find #{envname} database config" unless config
      if config['port'].blank?; config['port'] = '5432'; end
      system("cd #{Rails.root}; mysqldump --password=#{config['password']} --host=#{config['host']} --port=#{config['port']} --user=#{config['username']} --databases #{config['database']} | gzip -c | cat > tmp/dump.#{envname}-`date +%F-%T`.sql.gz") or raise("Failed to dump #{envname} DB")
    end
  end

end
