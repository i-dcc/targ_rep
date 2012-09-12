class GenbankFile < ActiveRecord::Base
  stampable

  attr_accessor :nested

  GenbankFile.include_root_in_json = false

  ##
  ## Associations
  ##

  belongs_to :allele, :class_name => "Allele", :foreign_key => "allele_id", :validate => true

  ##
  ## Validations
  ##

  validates_presence_of   :allele_id, :unless => :nested
  validates_uniqueness_of :allele_id, :message => "must be unique"

  def escell_clone_cre_excised
    return site_specific_recombination(escell_clone, 'cre')
  end

private
  def site_specific_recombination(genbank_file,flag)
    cre_excised_genbank_file =ruby IO.popen("CALL PERL MODULE OR SOMETHING???")
    cre_excised_genbank_file.close_write
    return cre_excised_genbank_file.read
  end

end

# == Schema Information
#
# Table name: genbank_files
#
#  id               :integer(4)      not null, primary key
#  allele_id        :integer(4)      not null
#  escell_clone     :text(2147483647
#  targeting_vector :text(2147483647
#  created_at       :datetime
#  updated_at       :datetime
#  created_by       :integer(4)
#  updated_by       :integer(4)
#
# Indexes
#
#  genbank_files_allele_id_fk  (allele_id)
#

