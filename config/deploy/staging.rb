set :deploy_to, "/software/team87/brave_new_world/capistrano_managed_apps/staging/#{application}"

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    var_run_path = '/var/run/team87/idcc_targ_rep/staging'
    
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml"
    
    # /tmp
    run "mkdir -m 777 -p #{var_run_path}/tmp"
    run "cd #{release_path} && rm -rf tmp && ln -nfs #{var_run_path}/tmp tmp"
    
    # /public/javascripts - the server needs write access...
    run "rm -rf #{var_run_path}/javascripts"
    run "cd #{release_path}/public && cp -r javascripts #{var_run_path}/javascripts && ln -nfs #{var_run_path}/javascripts javascripts"
    run "chmod g+w #{var_run_path}/javascripts"
  end
end

after "deploy:update_code", "deploy:symlink_shared"
