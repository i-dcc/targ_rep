class WelcomeController < ApplicationController
  def index
    @counts = {}
    Pipeline.all.each do |pipeline|
      @counts[pipeline.name] = {
        :molecular_structures   => pipeline.molecular_structures.count,
        :es_cells               => pipeline.es_cells.count
      }
    end
  end
end
