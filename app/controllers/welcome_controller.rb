class WelcomeController < ApplicationController
  def index
    
    # First fetch our counts from the DB - this direct SQL approach 
    # is much faster than going via the model....
    mol_str_counts = molecular_structure_count_by_pipeline()
    gene_counts    = gene_count_by_pipeline()
    vector_counts  = targeting_vector_count_by_pipeline()
    escell_counts  = escell_count_by_pipeline()
    
    @pipeline_counts = {}
    @total_counts    = {
      :pipelines            => 0,
      :molecular_structures => 0,
      :genes                => 0,
      :vectors              => 0,
      :es_cells             => 0
    }
    
    Pipeline.all.each do |pipeline|
      @pipeline_counts[pipeline.name] = {
        :molecular_structures => mol_str_counts[ pipeline.id ] ? mol_str_counts[ pipeline.id ] : 0,
        :genes                => gene_counts[ pipeline.id ] ? gene_counts[ pipeline.id ] : 0,
        :vectors              => vector_counts[ pipeline.id ] ? vector_counts[ pipeline.id ] : 0,
        :es_cells             => escell_counts[ pipeline.id ] ? escell_counts[ pipeline.id ] : 0
      }
      @total_counts[:pipelines] += 1
      @total_counts[:molecular_structures] += @pipeline_counts[pipeline.name][:molecular_structures]
      @total_counts[:genes] += @pipeline_counts[pipeline.name][:genes]
      @total_counts[:vectors] += @pipeline_counts[pipeline.name][:vectors]
      @total_counts[:es_cells] += @pipeline_counts[pipeline.name][:es_cells]
    end
  end
  
  private
  
  def molecular_structure_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id id,
        count(id) count
      from molecular_structures
      group by pipeline_id
    SQL
    run_count_sql(sql)
  end
  
  def gene_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id id,
        count(distinct mgi_accession_id) count
      from molecular_structures
      group by pipeline_id
    SQL
    run_count_sql(sql)
  end
  
  def targeting_vector_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id id,
        count(targeting_vectors.id) count
      from
        molecular_structures
        join targeting_vectors on targeting_vectors.molecular_structure_id = molecular_structures.id
      group by pipeline_id
    SQL
    run_count_sql(sql)
  end
  
  def escell_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id id,
        count(es_cells.id) count
      from
        molecular_structures
        join es_cells on es_cells.molecular_structure_id = molecular_structures.id
      group by pipeline_id
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
