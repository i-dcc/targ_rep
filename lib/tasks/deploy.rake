begin
  require 'vlad'
  require 'hoe/rake'
  require 'bundler/vlad'
  require 'tmpdir'
  require 'thread'
  
  Vlad.load({
    :web => :apache,
    :app => :passenger,
    :scm => :git
  })
  
rescue LoadError
  puts "[ERROR] Unable to load 'vlad' (deployment) tasks - please run 'bundle install'"
end