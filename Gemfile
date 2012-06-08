# see http://gembundler.com/rails23.html for details
source :rubygems

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
gem 'allele_image', :git => 'git@github.com:i-dcc/allele-imaging.git', :branch => 'cassetteonly'
gem 'rsolr'
gem 'hoptoad_notifier'
gem 'parallel'
gem 'httparty'
gem 'sequel'
gem 'mysql2', '< 0.3'
gem 'rdoc'

# bundler requires these gems in development and while running tests
group :development, :test do
  gem 'vlad',                 :require => false
  gem 'vlad-git',             :require => false
  gem 'hoe',                  :require => false
  gem 'shoulda', '> 2.11.0'
  gem 'factory_girl'
  gem 'test-unit'
  gem 'annotate'
  gem 'awesome_print'
  gem 'simplecov', '>= 0.4.0', :require => false
  gem 'simplecov-rcov',        :require => false
end
