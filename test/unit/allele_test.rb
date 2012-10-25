require 'test_helper'

class AlleleTest < ActiveSupport::TestCase
  setup do
    @allele = Factory.create( :allele )
    # allele has been saved successfully here
  end

  should have_many(:targeting_vectors)
  should have_many(:es_cells)
  should belong_to(:mutation_type)
  should belong_to(:mutation_subtype)
  should belong_to(:mutation_method)

  should validate_uniqueness_of(:project_design_id).scoped_to([
      :mgi_accession_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ]).with_message("must have unique design features")

  [
    :mgi_accession_id, :assembly, :chromosome,
    :strand, :mutation_type, :mutation_method, :homology_arm_start, :homology_arm_end,
    :cassette, :cassette_type
  ].each do |attribute|
    should validate_presence_of(attribute)
  end

  [
    :homology_arm_start, :homology_arm_end, :cassette_start, :cassette_end,
    :loxp_start, :loxp_end
  ].each do |attribute|
    should validate_numericality_of(attribute)
  end

  should_not allow_value(nil).for(:mutation_method)
  should_not allow_value(nil).for(:mutation_type)
  should allow_value(nil).for(:mutation_subtype)

  context "An Allele" do
    context "with empty attributes" do
      allele = Factory.build( :invalid_allele )
      should "not be saved" do
        assert( !allele.save, "Allele saves an empty entry" )
      end
    end

    should 'return mutation_method_name' do
      allele = Factory.create( :allele )
      name = allele.mutation_method.name
      assert_equal name, allele.mutation_method_name
    end

    should 'return mutation_type_name' do
      allele = Factory.create( :allele )
      name = allele.mutation_type.name
      assert_equal name, allele.mutation_type_name
    end

    should 'return mutation_subtype_name' do
      allele = Factory.create( :allele )
      name = allele.mutation_subtype.name
      assert_equal name, allele.mutation_subtype_name
    end

    context "with an incorrect MGI Accession ID" do
      should "not be saved" do
        allele = Factory.build( :allele, :mgi_accession_id => 'WRONG MGI' )
        assert( !allele.save, "Allele is saved with an incorrect MGI Accession ID" )
      end
    end

    context "with an incorrect floxed exon" do
      should "not be saved" do
        allele = Factory.build( :allele, :floxed_start_exon => 'ENSMUSG20913091309' )
        assert( !allele.save, "Allele is saved with an incorrect Ensembl Exon ID" )

        allele2 = Factory.build( :allele, :floxed_end_exon => 'ENSMUSG20913091309' )
        assert( !allele2.save, "Allele is saved with an incorrect Ensembl Exon ID" )
      end
    end

    context "with wrong strand" do
      should "not be saved" do
        allele = Factory.build( :allele, :strand => 'WRONG STRAND' )
        assert( !allele.save, "Allele is saved with a wrong strand" )
      end
    end

    context "with wrong chromosome" do
      should "not be saved" do
        allele = Factory.build( :allele, :chromosome => 'WRONG CHROMOSOME' )
        assert( !allele.save, "Allele is saved with a wrong chromosome" )
      end
    end

    context "with wrong homology arm position" do
      should "not be saved" do
        # Wrong start and end positions for the given strand
        @wrong_position1  = Factory.build( :allele, {
            :strand             => '+',
            :homology_arm_start => 2,
            :homology_arm_end   => 1
          })
        @wrong_position2  = Factory.build( :allele, {
            :strand             => '-',
            :homology_arm_start => 1,
            :homology_arm_end   => 2
          })

        # Homology arm site overlaps other features
        @wrong_position3  = Factory.build( :allele, {
            :strand             => '+',
            :homology_arm_start => 50,
            :homology_arm_end   => 120
          })
        @wrong_position4  = Factory.build( :allele, {
            :strand             => '-',
            :homology_arm_start => 120,
            :homology_arm_end   => 50
          })

        assert( !@wrong_position1.save, "Homology arm start cannot be greater than LoxP end on strand '+'" )
        assert( !@wrong_position2.save, "Homology arm end cannot be greater than LoxP start on strand '-'" )
        assert( !@wrong_position3.save, "Homology arm cannot overlap other features (strand '+')" )
        assert( !@wrong_position4.save, "Homology arm cannot overlap other features (strand '-')" )
      end
    end

    context "with wrong cassette position" do
      should "not be saved" do
        # Wrong start and end positions for the given strand
        @wrong_position1  = Factory.build( :allele, {
            :strand         => '+',
            :cassette_start => 2,
            :cassette_end   => 1
          })
        @wrong_position2  = Factory.build( :allele, {
            :strand         => '-',
            :cassette_start => 1,
            :cassette_end   => 2
          })

        # LoxP site overlaps other features
        @wrong_position3  = Factory.build( :allele, {
            :strand             => '+',
            :cassette_start     => 5,
            :cassette_end       => 170
          })
        @wrong_position4  = Factory.build( :allele, {
            :strand             => '-',
            :cassette_start     => 170,
            :cassette_end       => 5
          })

        assert( !@wrong_position1.save, "Cassette start cannot be greater than LoxP end on strand '+'" )
        assert( !@wrong_position2.save, "Cassette end cannot be greater than LoxP start on strand '-'" )
        assert( !@wrong_position3.save, "Cassette cannot overlap other features (strand '+')" )
        assert( !@wrong_position4.save, "Cassette cannot overlap other features (strand '-')" )
      end
    end

    context "with wrong LoxP position" do
      should "not be saved" do
        # Wrong start and end positions for the given strand
        @wrong_position1  = Factory.build( :allele, {
            :strand     => '+',
            :loxp_start => 2,
            :loxp_end   => 1
          })
        @wrong_position2  = Factory.build( :allele, {
            :strand     => '-',
            :loxp_start => 1,
            :loxp_end   => 2
          })

        # LoxP site overlaps other features
        @wrong_position3  = Factory.build( :allele, {
            :strand             => '+',
            :loxp_start         => 5,
            :loxp_end           => 170
          })
        @wrong_position4  = Factory.build( :allele, {
            :strand             => '-',
            :loxp_start         => 170,
            :loxp_end           => 5
          })

        assert( !@wrong_position1.save, "LoxP start cannot be greater than LoxP end (strand '+')" )
        assert( !@wrong_position2.save, "LoxP end cannot be greater than LoxP start (strand '-')" )
        assert( !@wrong_position3.save, "LoxP site cannot overlap other features (strand '+')" )
        assert( !@wrong_position4.save, "LoxP site cannot overlap other features (strand '-')" )
      end
    end

    context "with mutation type 'Deletion' and LoxP set" do
      should "not be saved" do
        allele = Factory.build( :allele, {
            :mutation_type        => MutationType.find_by_code!('del'),
            :strand             => '+',
            :loxp_start         => 100,
            :loxp_end           => 130
          })
        assert( !allele.save, "Allele validates presence of LoxP for mutation_type 'Deletion'" )
      end
    end

    context "with mutation type 'Insertion' and LoxP set" do
      should "not be saved" do
        allele = Factory.build( :allele, {
            :mutation_type        => MutationType.find_by_code!('ins'),
            :strand             => '+',
            :loxp_start         => 100,
            :loxp_end           => 130
          })
        assert( !allele.save, "Allele validates presence of LoxP for mutation_type 'cre-knock-in'" )
      end
    end

    should "not be saved with the wrong 'cassette_type' for a KNOWN cassette" do
      allele = Factory.build( :allele, { :cassette => 'L1L2_st1', :cassette_type => 'Promotor Driven' } )
      assert( !allele.save, "Allele 'has_correct_cassette_type' validation did not work for L1L2_st1!" )

      allele = Factory.build( :allele, { :cassette => 'L1L2_Bact_P', :cassette_type => 'Promotorless' } )
      assert( !allele.save, "Allele 'has_correct_cassette_type' validation did not work for L1L2_Bact_P!" )
    end

    should "be saved when the correct 'cassette_type' is entered though..." do
      allele = Factory.build( :allele, { :cassette => 'L1L2_st1', :cassette_type => 'Promotorless' } )
      assert( allele.save, "Allele 'has_correct_cassette_type' is not accepting L1L2_st1 as a Promotorless cassette!")
    end

    context '#unique_public_info' do
      setup do
        create_standard_pipelines
      end

      should "return an array of unique es cell data for public export" do
        strains = [['JM8A','C57BL/6N-A<tm1Brd>/a'], ['JM8A','C57BL/6N-A<tm1Brd>/a'], ['C2','C57BL/6N'], ['JM8A','C57BL/6N-A<tm1Brd>/a']]
        allele_symbol_superscript = ['tm1e(EUCOMM)Hmgu', 'tm1e(EUCOMM)WTSI', 'tm1e(EUCOMM)WTSI', 'tm1e(EUCOMM)WTSI']
        ikmc_project_ids = ['1', '2', '3', '2']
        allele = Factory.create :allele
        (0..3).each do |i|
          Factory.create :es_cell,
                  :allele => allele,
                  :parental_cell_line => strains[i][0],
                  :allele_symbol_superscript =>
                  allele_symbol_superscript[i],
                  :ikmc_project_id => ikmc_project_ids[i],
                  :pipeline => Pipeline.find_by_name!('EUCOMM')
        end
        #allele.reload
        allele = Allele.find(allele.id)
        unique_es_cells = allele.es_cells.unique_public_info
        assert_equal 3, unique_es_cells.count
        assert unique_es_cells.include?({:strain => strains[0][1], :allele_symbol_superscript => allele_symbol_superscript[0], :pipeline => 'EUCOMM', :ikmc_project_id => '1'})
        assert unique_es_cells.include?({:strain => strains[1][1], :allele_symbol_superscript => allele_symbol_superscript[1], :pipeline => 'EUCOMM', :ikmc_project_id => '2'})
        assert unique_es_cells.include?({:strain => strains[2][1], :allele_symbol_superscript => allele_symbol_superscript[2], :pipeline => 'EUCOMM', :ikmc_project_id => '3'})
      end

      should ', if there are ES cells that differ only in pipeline, just emit a row for the first one' do
        allele = Factory.create :allele
        Factory.create :es_cell, :allele => allele,
                :parental_cell_line => 'JM8A',
                :allele_symbol_superscript => 'tm1a(EUCOMM)WTSI',
                :pipeline => Pipeline.find_by_name!('EUCOMM'),
                :ikmc_project_id => '1'
        Factory.create :es_cell, :allele => allele,
                :parental_cell_line => 'JM8A',
                :allele_symbol_superscript => 'tm1a(EUCOMM)WTSI',
                :pipeline => Pipeline.find_by_name!('mirKO'),
                :ikmc_project_id => '1'
        #allele.reload
        allele = Allele.find(allele.id)
        unique_info = allele.es_cells.unique_public_info
        assert_equal 1, unique_info.size
        expected = {
          :strain => 'C57BL/6N-A<tm1Brd>/a',
          :allele_symbol_superscript => 'tm1a(EUCOMM)WTSI',
          :ikmc_project_id => '1',
          :pipeline => 'EUCOMM'
        }
        assert_equal(expected, unique_info.first)
      end
    end

  end
end

