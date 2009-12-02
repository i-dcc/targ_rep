class WelcomeController < ApplicationController
  def index
    @pipelines = Pipeline.find(:all)
    @molecular_structure_count = 0
    @product_count = 0
    @counts = {}
    @pipelines.each do |pipeline|
      @counts[pipeline.name] = {
        :molecular_structures  => pipeline.molecular_structures.count,
        :products => pipeline.es_cells.count
      }
      @molecular_structure_count += @counts[pipeline.name][:molecular_structures]
      @product_count += @counts[pipeline.name][:products]
    end
  end
end
