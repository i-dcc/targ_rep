require 'test_helper'

class GenbankFileTest < ActiveSupport::TestCase
  should belong_to(:allele)

  context "recombinate genbank es_clone sequence" do
    should "return a cre genbank file" do
      genbank = Factory.create genbank_file

      assert_nothing_raised genbank.escell_clone_cre
      escell_clone_cre_genbank_file = genbank.escell_clone_cre
      assert_false escell_clone_cre_genbank_file.blank?
    end

    should "return a flp genbank file" do
      genbank = Factory.create genbank_file

      assert_nothing_raised genbank.escell_clone_flp
      escell_clone_flp_genbank_file = genbank.escell_clone_flp
      assert_false escell_clone_flp_genbank_file.blank?
    end

    should "return a flp-cre genbank file" do
      genbank = Factory.create genbank_file

      assert_nothing_raised genbank.escell_clone_flp_cre
      escell_clone_flp_cre_genbank_file = genbank.escell_clone_flp_cre
      assert_false escell_clone_flp_cre_genbank_file.blank?
    end
  end

  context "recombinate genbank targeting_vector sequence" do
    should "return a cre genbank file" do
      genbank = Factory.create genbank_file

      assert_nothing_raised genbank.targeting_vector_cre
      targeting_vector_cre_genbank_file = genbank.targeting_vector_cre
      assert_false targeting_vector_cre_genbank_file.blank?
    end

    should "return a flp genbank file" do
      genbank = Factory.create genbank_file

      assert_nothing_raised genbank.targeting_vector_flp
      targeting_vector_flp_genbank_file = genbank.targeting_vector_flp
      assert_false targeting_vector_flp_genbank_file.blank?
    end

    should "return a flp-cre genbank file" do
      genbank = Factory.create genbank_file

      assert_nothing_raised genbank.targeting_vector_flp_cre
      targeting_vector_flp_cre_genbank_file = genbank.targeting_vector_flp_cre
      assert_false targeting_vector_flp_cre_genbank_file.blank?
    end
  end
end

