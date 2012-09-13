class SolrUpdate::Config
  def self.init_config
    pre_parsed_config = YAML.load_file("#{Rails.root}/config/solr_update.yml")
    @@config = pre_parsed_config.fetch(Rails.env)
    @@config.merge!(pre_parsed_config['all'])
  end
  private_class_method :init_config

  init_config

  def self.[](key)
    return @@config[key]
  end

  def self.fetch(key)
    return @@config.fetch(key)
  end

end
