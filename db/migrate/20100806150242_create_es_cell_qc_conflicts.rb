class CreateEsCellQcConflicts < ActiveRecord::Migration
  def self.up
    create_table :es_cell_qc_conflicts do |t|
      t.integer   :es_cell_id
      t.string    :qc_field,        :null => false
      t.string    :current_result,  :null => false
      t.string    :proposed_result, :null => false
      t.text      :comment
      
      t.integer   :created_by
      t.integer   :updated_by
      t.timestamps
    end
    
    add_foreign_key( :es_cell_qc_conflicts, :es_cells, :dependent => :delete, :name => 'es_cell_qc_conflicts_es_cell_id_fk' )
  end

  def self.down
    drop_table :es_cell_qc_conflicts
  end
end
