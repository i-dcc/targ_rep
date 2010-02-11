set :application, "idcc_targ_rep"
set :repository,  "git://github.com/dazoakley/targ_rep2.git"
set :branch, "master"
set :user, "do2"

set :scm, :git
set :deploy_via, :export
set :copy_compression, :bz2

set :keep_releases, 5
set :use_sudo, false

role :web, "localhost"
role :app, "localhost"
set :ssh_options, { :port => 10025 }

namespace :deploy do
  desc "Restart Passenger"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  
  desc "Set the permissions of the filesystem so that others in the team can deploy, and the team87 user can do their stuff"
  task :fix_perms do
    run "chgrp team87 #{release_path}/tmp"
    run "chgrp team87 #{release_path}/public"
    run "chmod 02775 #{release_path}"
  end
end

after "deploy:symlink", "deploy:fix_perms"
