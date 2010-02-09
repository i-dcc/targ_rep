set :deploy_to, "/software/team87/brave_new_world/capistrano_managed_apps/staging/#{application}"

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml"
    run "mkdir -m 777 -p /var/tmp/idcc_targ_rep/staging"
    run "cd #{release_path} && rm -rf tmp && ln -nfs /var/tmp/idcc_targ_rep/staging tmp"
  end
end

after "deploy:update_code", "deploy:symlink_shared"
