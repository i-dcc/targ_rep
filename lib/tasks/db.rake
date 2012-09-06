namespace :db do

  def get_db_config_for_env(envname)
    deployed_config_file = '/nfs/team87/services/vlad_managed_apps/production/targ_rep/shared/config/database.yml'

    config = YAML.load_file("#{Rails.root}/config/database.yml")[envname]
    if ! config and File.exist?("#{Rails.root}/config/database.#{envname}.yml")
      config = YAML.load_file("#{Rails.root}/config/database.#{envname}.yml")[envname]
    end
    if ! config and File.exist?(deployed_config_file)
      config = YAML.load_file(deployed_config_file)[envname]
    end

    if config['port'].blank?; config['port'] = '5432'; end

    raise "Cannot find #{envname} database config" unless config

    return config
  end

  ['development', 'staging', 'production'].each do |envname|
    desc "Dump #{envname} DB into tmp/dump.#{envname}.sql.gz"
    task "#{envname}:dump" do
      config = get_db_config_for_env(envname)
      system("cd #{Rails.root}; mysqldump --password=#{config['password']} --host=#{config['host']} --port=#{config['port']} --user=#{config['username']} --databases #{config['database']} | gzip -c > tmp/dump.#{envname}.sql.gz") or raise("Failed to dump #{envname} DB")
    end

    desc "Load tmp/dump.#{envname}.sql.gz into current environment DB"
    task "#{envname}:load" => [:environment] do
      config = get_db_config_for_env(Rails.env)
      system("cd #{Rails.root}; zcat tmp/dump.#{envname}.sql.gz | mysql --password=#{config['password']} --host=#{config['host']} --port=#{config['port']} --user=#{config['username']} #{config['database']}") or raise("Load failed")
    end

    desc "Copy the contents of the #{envname} DB into the current environment DB"

  end

end
