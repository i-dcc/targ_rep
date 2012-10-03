class CreateCentres < ActiveRecord::Migration
  def self.up
    create_table :centres do |t|
      t.string :name

      t.timestamps
    end

  end

  def self.down
    #execute "update users set centre_id=null"
    #execute "update distribution_qcs set centre_id=null"
    drop_table :centres
  end
end
