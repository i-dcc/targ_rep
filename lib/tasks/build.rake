namespace :build do

  desc 'back'
  task :back do
    Rake::Task['db:migrate:down'].invoke('VERSION=20120921101158')
  end

  desc 'forward'
  task :forward do
    Rake::Task['db:migrate'].invoke('VERSION=20120921101158')
    Rake::Task['db:seed'].invoke
    Rake::Task['db:migrate'].invoke
    system("#{RAILS_ROOT}/script/update_users.rb")
  end

end