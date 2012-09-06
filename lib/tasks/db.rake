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

  def get_mysql_connection_options_from_config(config)
    return "--password=#{config['password']} " +
            "--host=#{config['host']} " +
            "--port=#{config['port']} " +
            "--user=#{config['username']} "
  end

  ['staging', 'production'].each do |envname|

    desc "Dump #{envname} DB into tmp/dump.#{envname}.sql.gz"
    task "#{envname}:dump" do
      raise 'Cannot run in a live env!' if ['staging', 'production'].include? Rails.env
      config = get_db_config_for_env(envname)
      mysqldump_cmd = "mysqldump " +
              get_mysql_connection_options_from_config(config) +
              "--skip-add-drop-table " +
              "#{config['database']}"
      system("cd #{Rails.root}; #{mysqldump_cmd} | gzip -c > tmp/dump.#{envname}.sql.gz") or raise("Failed to dump #{envname} DB")
    end

    desc "Load tmp/dump.#{envname}.sql.gz into current environment DB"
    task "#{envname}:load" => ['db:drop', 'db:create', :environment] do
      raise 'Cannot run in a live env!' if ['staging', 'production'].include? Rails.env
      config = get_db_config_for_env(Rails.env)

      mysql_connection_options = get_mysql_connection_options_from_config(config)

      mysqldump_cmd = "mysqldump " +
              "--no-data --add-drop-table " +
              mysql_connection_options
              "#{config['database']}"
      system("cd #{Rails.root}; zcat tmp/dump.#{envname}.sql.gz | mysql #{get_mysql_connection_options_from_config(config)} #{config['database']}") or raise("Load failed")
    end

    desc "Copy the contents of the #{envname} DB into the current environment DB"
    task "#{envname}:clone" => ["#{envname}dump", "#{envname}:load"]
  end

end
