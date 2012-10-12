class CreateCentres < ActiveRecord::Migration
  def self.up
    create_table :centres do |t|
      t.string :name

      t.timestamps
    end

    Centre.create!(:id => 1, :name => "WTSI")
    Centre.create!(:id => 2, :name => "KOMP")
    Centre.create!(:id => 3, :name => "EUCOMM")
  end

  def self.down
    drop_table :centres
  end
end
