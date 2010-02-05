set :deploy_to, "/software/team87/brave_new_world/capistrano_managed_apps/production/#{application}"

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/log /software/team87/brave_new_world/logs/idcc_targ_rep/production"
    run "mkdir -m 777 -p /var/tmp/idcc_targ_rep/production"
    run "ln -nfs #{shared_path}/tmp /var/tmp/idcc_targ_rep/production"
  end
end

after "deploy:update_code", "deploy:symlink_shared"
