# see http://gembundler.com/rails23.html for details
source :rubygems
gem "rails", "2.3.10"
gem "sqlite3-ruby", :require => "sqlite3"

# bundler requires these gems in all environments
gem "will_paginate", '~> 2.3.15'
gem "authlogic"
gem "searchlogic"
gem "acts_as_audited"
gem "foreigner"
gem "allele_image"
gem "rsolr"
gem "newrelic_rpm"
gem 'hoptoad_notifier'

group :development, :test do
  # bundler requires these gems in development and while running tests
  gem "shoulda", "> 2.11.0"
  gem "factory_girl"
  gem 'test-unit'
end
