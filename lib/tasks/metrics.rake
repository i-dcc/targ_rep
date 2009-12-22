begin
  require "metric_fu"
  MetricFu::Configuration.run do |config| 
    config.metrics  = [:stats, :churn, :saikuro, :flog, :flay, :reek, :roodi, :rcov]
    config.graphs   = [:flog, :flay, :reek, :roodi, :rcov]
    config.flog     = { :dirs_to_flog  => ["app","lib"] }
    config.flay     = { :dirs_to_flay  => ["app","lib"] }
    config.reek     = { :dirs_to_reek  => ["app","lib"] }
    config.roodi    = { :dirs_to_roodi => ["app","lib"] }
    config.rcov     = { 
                        :test_files => ["test/**/*_test.rb"],
                        :rcov_opts  => [
                          "--sort coverage", 
                          "--no-html", 
                          "--text-coverage",
                          "--no-color",
                          "--profile",
                          "--exclude /gems/,/Library/,spec,features"
                        ]
                      }
  end
rescue LoadError
end