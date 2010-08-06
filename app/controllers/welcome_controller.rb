class WelcomeController < ApplicationController
  def index
    
    # First fetch our counts from the DB - this direct SQL approach 
    # is much faster than going via the model....
    allele_counts = allele_count_by_pipeline()
    gene_counts   = gene_count_by_pipeline()
    vector_counts = targeting_vector_count_by_pipeline()
    escell_counts = escell_count_by_pipeline()
    
    @pipeline_counts = {}
    @total_counts    = {
      :pipelines => 0,
      :alleles   => 0,
      :genes     => 0,
      :vectors   => 0,
      :es_cells  => 0
    }
    
    Pipeline.all.each do |pipeline|
      @pipeline_counts[pipeline.name] = {
        :alleles  => allele_counts[ pipeline.id ] ? allele_counts[ pipeline.id ] : 0,
        :genes    => gene_counts[ pipeline.id ]   ? gene_counts[ pipeline.id ]   : 0,
        :vectors  => vector_counts[ pipeline.id ] ? vector_counts[ pipeline.id ] : 0,
        :es_cells => escell_counts[ pipeline.id ] ? escell_counts[ pipeline.id ] : 0
      }
      @total_counts[:pipelines] += 1
      @total_counts[:alleles]   += @pipeline_counts[pipeline.name][:alleles]
      @total_counts[:genes]     += @pipeline_counts[pipeline.name][:genes]
      @total_counts[:vectors]   += @pipeline_counts[pipeline.name][:vectors]
      @total_counts[:es_cells]  += @pipeline_counts[pipeline.name][:es_cells]
    end
  end
  
  private
  
  def allele_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id id,
        count(id) count
      from alleles
      group by pipeline_id
    SQL
    run_count_sql(sql)
  end
  
  def gene_count_by_pipeline
    sql = <<-SQL
      select
        pipeline_id id,
        count(distinct mgi_accession_id) count
      from alleles
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
        alleles
        join targeting_vectors on targeting_vectors.allele_id = alleles.id
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
        alleles
        join es_cells on es_cells.allele_id = alleles.id
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
