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

  def escell_clone_cre
    return site_specific_recombination(self.escell_clone, 'apply_cre')
  end

  def targeting_vector_cre
    return site_specific_recombination(self.targeting_vector, 'apply_cre')
  end

  def escell_clone_flp
    return site_specific_recombination(self.escell_clone, 'apply_flp')
  end

  def targeting_vector_flp
    return site_specific_recombination(self.targeting_vector, 'apply_flp')
  end

  def escell_clone_flp_cre
    return site_specific_recombination(self.escell_clone, 'apply_flp_cre')
  end

  def targeting_vector_flp_cre
    return site_specific_recombination(self.targeting_vector, 'apply_flp_cre')
  end

private
  def site_specific_recombination(genbank_file,flag)
    require "open3"
    if !genbank_file.blank?
      Open3.popen3("#{GENBANK_RECOMBINATION_PATH}recombinate_sequence.pl --#{flag}") do |std_in, std_out, std_err|
        std_in.write(genbank_file)
        std_in.close_write
        if !std_err.blank?
          return std_out.read
        else
          raise "Error: #{std_err.read}"
        end
      end
    else
      raise "Error: No Genbank File Found"
    end
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

