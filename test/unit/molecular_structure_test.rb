require 'test_helper'

class MolecularStructureTest < ActiveSupport::TestCase
  setup do
    @molecular_structure = Factory.create( :molecular_structure )
    # Molecular structure has been saved successfully here
  end
  
  should belong_to(:pipeline)
  should belong_to(:created_by)
  should belong_to(:updated_by)
  should have_many(:targeting_vectors)
  should have_many(:es_cells)
  
  should validate_uniqueness_of(:project_design_id).scoped_to([
      :mgi_accession_id, :assembly, :chromosome, :strand,
      :cassette, :backbone,
      :homology_arm_start, :homology_arm_end,
      :cassette_start, :cassette_end,
      :loxp_start, :loxp_end
    ]).with_message("must have unique design features")
  
  should validate_presence_of(:pipeline_id)
  should validate_presence_of(:mgi_accession_id)
  should validate_presence_of(:assembly)
  should validate_presence_of(:chromosome)
  should validate_presence_of(:strand)
  should validate_presence_of(:design_type)
  should validate_presence_of(:homology_arm_start)
  should validate_presence_of(:homology_arm_end)
  
  should validate_numericality_of(:homology_arm_start)
  should validate_numericality_of(:homology_arm_end)
  should validate_numericality_of(:cassette_start)
  should validate_numericality_of(:cassette_end)
  should validate_numericality_of(:loxp_start)
  should validate_numericality_of(:loxp_end)
  
  context "Molecular structure" do
    context "with empty attributes" do
      mol_struct = Factory.build( :invalid_molecular_structure )
      should "not be saved" do
        assert( !mol_struct.save, "Molecular structure saves an empty entry" )
      end
    end
    
    context "with wrong MGI" do
      should "not be saved" do
        mol_struct = Factory.build( :molecular_structure, :mgi_accession_id => 'WRONG MGI' )
        assert( !mol_struct.save, "Molecular structure is saved with a wrong MGI accession ID" )
      end
    end
    
    context "with wrong strand" do
      should "not be saved" do
        mol_struct = Factory.build( :molecular_structure, :strand => 'WRONG STRAND' )
        assert( !mol_struct.save, "Molecular structure is saved with a wrong strand" )
      end
    end
    
    context "with wrong chromosome" do
      should "not be saved" do
        mol_struct = Factory.build( :molecular_structure, :chromosome => 'WRONG CHROMOSOME' )
        assert( !mol_struct.save, "Molecular structure is saved with a wrong chromosome" )
      end
    end
    
    context "with wrong homology arm position" do
      should "not be saved" do
        # Wrong start and end positions for the given strand
        @wrong_position1  = Factory.build( :molecular_structure, {
                              :strand             => '+',
                              :homology_arm_start => 2,
                              :homology_arm_end   => 1
                            })
        @wrong_position2  = Factory.build( :molecular_structure, {
                              :strand             => '-',
                              :homology_arm_start => 1,
                              :homology_arm_end   => 2
                            })

        # Homology arm site overlaps other features
        @wrong_position3  = Factory.build( :molecular_structure, {
                              :strand             => '+',
                              :homology_arm_start => 50,
                              :homology_arm_end   => 120
                            })
        @wrong_position4  = Factory.build( :molecular_structure, {
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
        @wrong_position1  = Factory.build( :molecular_structure, {
                              :strand         => '+',
                              :cassette_start => 2,
                              :cassette_end   => 1
                            })
        @wrong_position2  = Factory.build( :molecular_structure, {
                              :strand         => '-',
                              :cassette_start => 1,
                              :cassette_end   => 2
                            })
        
        # LoxP site overlaps other features
        @wrong_position3  = Factory.build( :molecular_structure, {
                              :strand             => '+',
                              :cassette_start     => 5,
                              :cassette_end       => 170
                            })
        @wrong_position4  = Factory.build( :molecular_structure, {
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
        @wrong_position1  = Factory.build( :molecular_structure, {
                              :strand     => '+',
                              :loxp_start => 2,
                              :loxp_end   => 1
                            })
        @wrong_position2  = Factory.build( :molecular_structure, {
                              :strand     => '-',
                              :loxp_start => 1,
                              :loxp_end   => 2
                            })
        
        # LoxP site overlaps other features
        @wrong_position3  = Factory.build( :molecular_structure, {
                              :strand             => '+',
                              :loxp_start         => 5,
                              :loxp_end           => 170
                            })
        @wrong_position4  = Factory.build( :molecular_structure, {
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
    
    context "with design type 'Deletion' and LoxP set" do
      should "not be saved" do
        mol_struct = Factory.build( :molecular_structure, {
                        :design_type        => 'Deletion',
                        :strand             => '+',
                        :loxp_start         => 100,
                        :loxp_end           => 130
                      })
        assert( !mol_struct.save, "Molecular structure validates presence of LoxP for design 'Deletion'" )
      end
    end
    
    context "with design type 'Insertion' and LoxP set" do
      should "not be saved" do
        mol_struct = Factory.build( :molecular_structure, {
                        :design_type        => 'Insertion',
                        :strand             => '+',
                        :loxp_start         => 100,
                        :loxp_end           => 130
                      })
        assert( !mol_struct.save, "Molecular structure validates presence of LoxP for design 'Insertion'" )
      end
    end
  end
end
