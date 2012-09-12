module SolrUpdate::IndexProxy

  def self.get_uri_for(name)
    return URI.parse(YAML.load_file(Rails.root + 'config/solr_update.yml').fetch(Rails.env).fetch('index_proxy').fetch(name))
  end

  class Gene
    def initialize
      @solr_uri = SolrUpdate::IndexProxy.get_uri_for('gene').freeze
      if ENV['HTTP_PROXY'].present?
        proxy_uri = URI.parse(ENV['HTTP_PROXY'])
      end
      @http = Net::HTTP::Proxy(proxy_uri.host, proxy_uri.port, proxy_uri.user, proxy_uri.password)
    end

    def get_marker_symbol(mgi_accession_id)
      doc = nil
      uri = @solr_uri.dup
      uri.query = {:q => "mgi_accession_id:\"#{mgi_accession_id}\"", :wt => 'json'}.to_query
      @http.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        response = JSON.parse(http.request(request).body)
        doc = response.fetch('response').fetch('docs').first
      end
      return doc.fetch('marker_symbol')
    end
  end

  class Allele
  end

end
