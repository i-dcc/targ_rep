class MovePipelineIdOntoProducts < ActiveRecord::Migration
  def self.up
    add_column :targeting_vectors, :pipeline_id, :integer
    add_foreign_key( :targeting_vectors, :pipelines, :dependent => :delete, :name => 'targeting_vectors_pipeline_id_fk' )
    
    add_column :es_cells, :pipeline_id, :integer
    add_foreign_key( :es_cells, :pipelines, :dependent => :delete, :name => 'es_cells_pipeline_id_fk' )
    
    Allele.all.each do |allele|
      execute("update targeting_vectors set pipeline_id = #{allele.pipeline_id} where allele_id = #{allele.id}")
      execute("update es_cells set pipeline_id = #{allele.pipeline_id} where allele_id = #{allele.id}")
    end
    
    begin
      remove_foreign_key( :alleles, :pipelines )
    rescue
      execute("alter table alleles drop foreign key molecular_structures_pipeline_id_fk")
    end
    
    remove_column :alleles, :pipeline_id
  end

  def self.down
    add_column :alleles, :pipeline_id, :integer
    add_foreign_key :alleles, :pipelines, :dependent => :delete, :name => 'alleles_pipeline_id_fk'
    
    Allele.all.each do |allele|
      target_prod = allele.es_cells.first
      target_prod = allele.targeting_vectors.first if target_prod.nil?
      unless target_prod.nil?
        execute("update alleles set pipeline_id = #{target_prod.pipeline_id} where id = #{allele.id}")
      end
    end
    
    remove_foreign_key( :es_cells, :pipelines )
    remove_column :es_cells, :pipeline_id
    
    remove_foreign_key( :targeting_vectors, :pipelines )
    remove_column :targeting_vectors, :pipeline_id
  end
end
