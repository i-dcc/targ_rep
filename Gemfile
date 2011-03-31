# see http://gembundler.com/rails23.html for details
source :rubygems

# rails requires these gems
gem "rails", "2.3.11"

# bundler requires these gems in all environments
gem "biomart"
gem "will_paginate", '~> 2.3.15'
gem "authlogic"
gem "searchlogic"
gem "acts_as_audited"
gem "foreigner"
gem "allele_image", "0.3.4", :git => "http://github.com/i-dcc/allele-imaging.git", :tag => "v0.3.4"
gem "rsolr"
gem "newrelic_rpm"
gem "hoptoad_notifier"
gem "parallel"
gem "httparty"
gem "sequel"
gem "mysql2"

# bundler requires these gems in development and while running tests
group :development, :test do
  gem "capistrano"
  gem "capistrano-ext"
  gem "shoulda", "> 2.11.0"
  gem "factory_girl"
  gem "test-unit"
end
