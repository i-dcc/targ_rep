module SolrUpdate::IndexProxy

  class Gene
    def initialize
      @solr_uri = URI.parse(YAML.load_file(Rails.root + 'config/solr_update.yml')['index_proxy'].fetch('gene')).freeze
      proxy_uri = URI.parse(ENV['HTTP_PROXY'])
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
