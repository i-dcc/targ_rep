# encoding: utf-8

set :application,       'targ_rep'
set :repository,        'git@github.com:i-dcc/targ_rep.git'
set :revision,          'origin/master'

set :domain,            'htgt.internal.sanger.ac.uk'
set :service_user,      'team87'
set :bnw_env,           '/software/bin/perl -I/software/team87/brave_new_world/lib/perl5 -I/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi /software/team87/brave_new_world/bin/htgt-env.pl --live' 
set :bundle_cmd,        "#{bnw_env} bundle"
set :web_command,       "#{bnw_env} sudo -u #{service_user} /software/team87/brave_new_world/services/apache2-ruby19"

##
## Environments
##

task :production do
  set :deploy_to, "/nfs/team87/services/vlad_managed_apps/production/#{application}"
end

task :staging do
  set :deploy_to, "/nfs/team87/services/vlad_managed_apps/staging/#{application}"
end

##
## Tasks
##

desc "Full deployment cycle: update, bundle, symlink, restart, cleanup"
task :deploy => %w[
  vlad:update
  vlad:bundle:install
  vlad:symlink_config
  vlad:start_app
  vlad:fix_perms
  vlad:cleanup
]

# only ever run this ONCE for a server/config
task :setup_new_instance => %w[
  vlad:setup
  vlad:update
  vlad:bundle:install
  vlad:symlink_config
  vlad:fix_perms
]

namespace :vlad do
  desc "Symlinks the configuration files"
  remote_task :symlink_config, :roles => :app do
    %w[ database.yml ].each do |file|
      run "ln -nfs #{shared_path}/config/#{file} #{current_path}/config/#{file}"
    end
  end
  
  desc "Fixes the permissions on the 'current' deployment"
  remote_task :fix_perms, :roles => :app do
    fix_perms_you     = "find #{deploy_to}/ -user #{`whoami`.chomp}" + ' \! \( -perm -u+rw -a -perm -g+rw \) -exec chmod -v ug=rwX,o=rX {} \;'
    fix_perms_service = "sudo -u #{service_user} find #{releases_path}/ -user #{service_user}" + ' \! \( -perm -u+rw -a -perm -g+rw \) -exec chmod -v ug=rwX,o=rX {} \;'
    
    run fix_perms_you
    run fix_perms_service
  end
  
  task :setup do
    Rake::Task['vlad:setup_shared'].invoke
  end
  
  remote_task :setup_shared, :roles => :app do
    commands = [
      "umask #{umask}",
      "mkdir -p #{shared_path}/config",
      "ln -nfs /software/team87/brave_new_world/conf/ols_database.yml #{shared_path}/config/ols_database.yml"
    ]
    
    run commands.join(' && ')
  end
  
  Rake.clear_tasks('vlad:start_app')
  remote_task :start_app, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
end
