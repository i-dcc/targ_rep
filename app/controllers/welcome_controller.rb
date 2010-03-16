class WelcomeController < ApplicationController
  def index
    
    # First fetch our counts from the DB - this direct SQL approach 
    # is much faster than going via the model....
    mol_str_counts = molecular_structure_count_by_pipeline()
    escell_counts  = escell_count_by_pipeline()
    
    @pipeline_counts = {}
    @total_counts    = {
      :pipelines            => 0,
      :molecular_structures => 0,
      :es_cells             => 0
    }
    
    Pipeline.all.each do |pipeline|
      @pipeline_counts[pipeline.name] = {
        :molecular_structures => mol_str_counts[ pipeline.id ] ? mol_str_counts[ pipeline.id ] : 0,
        :es_cells             => escell_counts[ pipeline.id ] ? escell_counts[ pipeline.id ] : 0,
      }
      @total_counts[:pipelines] += 1
      @total_counts[:molecular_structures] += @pipeline_counts[pipeline.name][:molecular_structures]
      @total_counts[:es_cells] += @pipeline_counts[pipeline.name][:es_cells]
    end
  end
  
  private
  
  def molecular_structure_count_by_pipeline
    sql = <<-SQL
      SELECT
        pipeline_id id,
        COUNT(id) count
      FROM molecular_structures
      GROUP BY pipeline_id
    SQL
    run_count_sql(sql)
  end
  
  def escell_count_by_pipeline
    sql = <<-SQL
      SELECT
        pipeline_id id,
        COUNT(es_cells.id) count
      FROM
        molecular_structures
        JOIN es_cells ON es_cells.molecular_structure_id = molecular_structures.id
      GROUP BY pipeline_id
    SQL
    run_count_sql(sql)
  end
  
  def run_count_sql(sql)
    counts  = {}
    results = ActiveRecord::Base.connection.execute(sql)
    
    results.each_hash do |res|
      counts[ res["id"].to_i ] = res["count"].to_i
    end
    
    return counts
  end
  
end
