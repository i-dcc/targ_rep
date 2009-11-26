class WelcomeController < ApplicationController
  def index
    @pipelines = Pipeline.find(:all)
    @allele_count = 0
    @product_count = 0
    @counts = {}
    @pipelines.each do |pipeline|
      @counts[pipeline.name] = { 
        :alleles  => pipeline.targeting_vectors.count
      }
      @allele_count = @allele_count + @counts[pipeline.name][:alleles]
      # @product_count = @product_count + @counts[pipeline.name][:products]
    end
  end
end
