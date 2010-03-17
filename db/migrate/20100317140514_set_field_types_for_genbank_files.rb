class SetFieldTypesForGenbankFiles < ActiveRecord::Migration
  def self.up
    execute "alter table genbank_files change escell_clone escell_clone longtext"
    execute "alter table genbank_files change targeting_vector targeting_vector longtext"
  end

  def self.down
    execute "alter table genbank_files change escell_clone escell_clone text"
    execute "alter table genbank_files change targeting_vector targeting_vector text"
  end
end
