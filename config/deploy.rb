set :application, "idcc_targ_rep"
set :repository,  "git://github.com/i-dcc/targ_rep.git"
set :branch, "master"
set :user, `whoami`.chomp

set :scm, :git
set :deploy_via, :export
set :copy_compression, :bz2

set :keep_releases, 5
set :use_sudo, false

role :web, 'etch-dev64.internal.sanger.ac.uk'
role :app, 'etch-dev64.internal.sanger.ac.uk'
role :db,  'etch-dev64.internal.sanger.ac.uk', :primary => true

set :default_environment, {
  'PATH'      => '/software/team87/brave_new_world/bin:/software/perl-5.8.8/bin:/usr/bin:/bin',
  'PERL5LIB'  => '/software/team87/brave_new_world/lib/perl5:/software/team87/brave_new_world/lib/perl5/x86_64-linux-thread-multi'
}

set :bundle_cmd, '/software/team87/brave_new_world/bin/htgt-env.pl --environment Ruby19 /software/team87/brave_new_world/app/ruby-1.9.2-p0/lib/ruby/gems/1.9/bin/bundle'

namespace :deploy do
  desc "Restart Passenger"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
    sleep 10
    run "rm #{File.join(current_path,'tmp','restart.txt')}"
  end
  
  desc "Set the permissions of the filesystem so that others in the team can deploy, and the team87 user can do their stuff"
  task :fix_perms do
    run "chgrp -R team87 #{release_path}/tmp"
    run "chgrp -R team87 #{release_path}/public"
    run "chmod 02775 #{release_path}"
  end
end

after "deploy:symlink", "deploy:fix_perms"
