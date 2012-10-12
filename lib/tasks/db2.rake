#require 'colorize'

namespace :db2 do

  DEBUG = false

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

  if ENV['RAILS_ENV'] != 'production'
    ['staging', 'production'].each do |envname|

      desc "Dump (part) #{envname} DB into tmp/dump.#{envname}_partial.sql.gz"
      task "#{envname}:dump_partial" do



        if File.readlines("#{Rails.root}/config/environment.rb").grep(/^\s*config.active_record.observers\s+=/).any?
          #raise "### Comment-out config.active_record.observers in environment.rb! ###".red
          raise "### Comment-out config.active_record.observers in environment.rb! ###"
        end

        #/nfs/users/nfs_r/re4/dev/targ_rep/config/environment.rb

        #exit



        #puts "DEBUG enabled!".green if DEBUG

        raise 'Cannot run in live env!' if Rails.env.production?
        config = get_db_config_for_env(envname)

        raise "#### Are you sure you want to use '#{config['database']}' as production db?" if envname == 'production' && config['database'] != 'idcc_30082012'

        mysqldump_cmd = "mysqldump " +
                "--ignore-table=#{config['database']}.genbank_files " +
                "--ignore-table=#{config['database']}.genbank_files_vw " +
                get_mysql_connection_options_from_config(config) +
                "#{config['database']}"

        mysqldump_cmd2 = "mysqldump " +
                get_mysql_connection_options_from_config(config) +
                " --no-data #{config['database']} genbank_files "

        mysqldump_cmd3 = "mysqldump " +
                get_mysql_connection_options_from_config(config) +
                " --no-data #{config['database']} genbank_files_vw "

        puts "cd #{Rails.root}; #{mysqldump_cmd} > tmp/dump.#{envname}_partial.sql" if DEBUG
        system("cd #{Rails.root}; #{mysqldump_cmd} > tmp/dump.#{envname}_partial.sql") or raise("Failed to dump #{envname} DB") if ! DEBUG


        puts "cd #{Rails.root}; #{mysqldump_cmd2} >> tmp/dump.#{envname}_partial.sql" if DEBUG
        system("cd #{Rails.root}; #{mysqldump_cmd2} >> tmp/dump.#{envname}_partial.sql") or raise("Failed to dump #{envname} DB") if ! DEBUG

        puts "cd #{Rails.root}; #{mysqldump_cmd3} >> tmp/dump.#{envname}_partial.sql" if DEBUG
        system("cd #{Rails.root}; #{mysqldump_cmd3} >> tmp/dump.#{envname}_partial.sql") or raise("Failed to dump #{envname} DB") if ! DEBUG

        puts "cd #{Rails.root}; gzip -f tmp/dump.#{envname}_partial.sql" if DEBUG
        system("cd #{Rails.root}; gzip -f tmp/dump.#{envname}_partial.sql") or raise("Failed to zip file #{envname} DB") if ! DEBUG
      end

      desc "Load (part) tmp/dump.#{envname}_partial.sql.gz into current environment DB"
      task "#{envname}:load_partial" => ['db:drop', 'db:create', :environment] do
        raise 'Cannot run in live env!' if Rails.env.production?
        config = get_db_config_for_env(Rails.env)

        mysql_connection_options = get_mysql_connection_options_from_config(config)

        mysqldump_cmd = "mysqldump " +
                "--no-data --add-drop-table " +
                mysql_connection_options
        "#{config['database']}"

        puts "cd #{Rails.root}; zcat tmp/dump.#{envname}_partial.sql.gz | mysql #{get_mysql_connection_options_from_config(config)} #{config['database']}" if DEBUG
        system("cd #{Rails.root}; zcat tmp/dump.#{envname}_partial.sql.gz | mysql #{get_mysql_connection_options_from_config(config)} #{config['database']}") or raise("Load failed") if ! DEBUG
      end

      desc "Copy (less genbank) the contents of the #{envname} DB into the current environment DB"
      task "#{envname}:clone_partial" => ["#{envname}:dump_partial", "#{envname}:load_partial"]
    end
  end

end
