load 'deploy' if respond_to?(:namespace) # cap2 differentiator
Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy' # remove this line to skip loading any of the default tasks

set :stages, ["staging", "production"]
set :default_stage, "staging"
require "capistrano/ext/multistage"
require "config/deploy/natcmp.rb"
require "config/deploy/gitflow.rb"
