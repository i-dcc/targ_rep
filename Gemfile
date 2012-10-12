# see http://gembundler.com/rails23.html for details
source :rubygems
source 'http://www.i-dcc.org/rubygems/'

# rails requires these gems
gem 'rails', '~> 2.3.12'
gem 'rake'

# bundler requires these gems in all environments
gem 'biomart'
gem 'will_paginate', '~> 2.3.15'
gem 'authlogic'
gem 'searchlogic'
gem 'acts_as_audited'
gem 'foreigner'
gem 'allele_image', :git => 'git://github.com/i-dcc/allele_image.git'
gem 'rsolr'
gem 'hoptoad_notifier'
gem 'parallel'
gem 'httparty'
gem 'sequel'
gem 'mysql2', '< 0.3'
gem 'rdoc'
gem 'json_pure'
gem 'mpi2_solr_update'

# bundler requires these gems in development and while running tests
group :development, :test do
  gem 'vlad',                  :require => false
  gem 'vlad-git',              :require => false
  gem 'hoe',                   :require => false
  gem 'shoulda',               :require => false
  gem 'factory_girl', '~>2.6.4'
  gem 'test-unit',             :require => false
  gem 'annotate'
  gem 'awesome_print'
  gem 'mocha',                 :require => false
end
