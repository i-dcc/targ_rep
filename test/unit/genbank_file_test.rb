require 'test_helper'

class GenbankFileTest < ActiveSupport::TestCase
  should belong_to(:allele)
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

