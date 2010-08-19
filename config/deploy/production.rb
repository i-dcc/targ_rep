set :deploy_to, "/software/team87/brave_new_world/capistrano_managed_apps/production/#{application}"

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    var_run_path = '/nfs/team87/services/var/idcc_targ_rep/production'
    
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml"
    
    # /tmp
    run "mkdir -m 777 -p #{var_run_path}/tmp"
    run "cd #{release_path} && rm -rf tmp && ln -nfs #{var_run_path}/tmp tmp"
    
    # /public/javascripts - the server needs write access...
    run "rm -rf #{var_run_path}/javascripts"
    run "cd #{release_path}/public && mv javascripts #{var_run_path}/javascripts && ln -nfs #{var_run_path}/javascripts javascripts"
    run "chgrp team87 #{var_run_path}/javascripts && chmod g+w #{var_run_path}/javascripts"
    
    # /public/downloads - auto-generated datafiles
    run "mkdir -p #{var_run_path}/downloads"
    run "cd #{release_path}/public && rm -rf downloads && ln -nfs #{var_run_path}/downloads downloads"
    run "chgrp team87 #{var_run_path}/downloads && chmod g+w #{var_run_path}/downloads"
  end
end

after "deploy:update_code", "deploy:symlink_shared"
