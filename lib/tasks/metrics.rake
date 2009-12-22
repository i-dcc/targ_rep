begin
  require "metric_fu"
  MetricFu::Configuration.run do |config| 
    config.metrics  = [:stats, :churn, :saikuro, :flog, :flay, :reek, :roodi]
    config.graphs   = [:flog, :flay, :reek, :roodi]
    config.flog     = { :dirs_to_flog  => ["app","lib"] }
    config.flay     = { :dirs_to_flay  => ["app","lib"] }
    config.reek     = { :dirs_to_reek  => ["app","lib"] }
    config.roodi    = { :dirs_to_roodi => ["app","lib"] }
  end
rescue LoadError
end