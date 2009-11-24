class CreatePipelines < ActiveRecord::Migration
  def self.up
    create_table :pipelines do |t|
      t.string :name, :null => false
      t.timestamps
    end
  end
  
  def self.down
    drop_table :pipelines
  end
end
