class CreateCentres < ActiveRecord::Migration
  def self.up
    create_table :centres do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :centres
  end
end
