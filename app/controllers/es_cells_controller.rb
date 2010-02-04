class EsCellsController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_escell, :only => [:show, :update, :destroy]
  
  # GET /es_cells.xml
  # GET /es_cells.json
  def index
    if params.include? :name
      @es_cells = EsCell.name_like( params[:name] )
      @es_cells = @es_cells.all
    else
      @es_cells = EsCell.all
    end
    @es_cells = @es_cells.paginate(:page => params[:page])
    
    respond_to do |format|
      format.xml  { render :xml   => @es_cells }
      format.json { render :json  => @es_cells }
    end
  end

  # GET /es_cells/1.xml
  # GET /es_cells/1.json
  def show
    respond_to do |format|
      format.xml  { render :xml   => @es_cell }
      format.json { render :json  => @es_cell }
    end
  end

  # POST /es_cells.xml
  # POST /es_cells.json
  def create
    es_cell_hash = params[:es_cell].dup
    
    errors = []
    
    if es_cell_hash.include? :molecular_structure and es_cell_hash.include? :molecular_structure_id
      errors << { "ES Cell is invalid" =>
        "should have only one molecular structure representation (id or hash)"
      }
    end
    
    if es_cell_hash.include? :targeting_vector and es_cell_hash.include? :targeting_vector_id
      errors << {"ES Cell is invalid" =>
        "should have only one targeting vector representation (id or hash)"
      }
    end
    
    
    #
    # Get or Create Molecular Structure
    #
    
    if errors.empty?
      # Get molecular structure from ID
      if es_cell_hash.include? :molecular_structure_id
        mol_struct_created = false
        @mol_struct = MolecularStructure.find( es_cell_hash[ :molecular_structure_id ] )
      
      # Create molecular structure from hash
      elsif es_cell_hash.include? :molecular_structure
        mol_struct_created = true
        @mol_struct = MolecularStructure.new( es_cell_hash[ :molecular_structure ] )
        
        unless @mol_struct.save
          errors << { "Molecular Structure is invalid" => @mol_struct.errors }
        end
      end
    end
    
    
    #
    # Get or Create Targeting Vector
    #
    
    if errors.empty?
      
      # GET targeting vector from ID
      if es_cell_hash.include? :targeting_vector_id
        targ_vec_created = false
        @targ_vec = TargetingVector.find( es_cell_hash[ :targeting_vector_id ] )
        
        # Check if targeting vector is link to a molecular structure that is
        # similar to the molecular structure provided
        unless @targ_vec.molecular_structure.id == @mol_struct.id         \
        or (@mol_struct.mgi_accession_id  == @targ_vec.mgi_accession_id   \
        and @mol_struct.project_design_id == @targ_vec.project_design_id  \
        and @mol_struct.design_type       == @targ_vec.design_type        \
        and @mol_struct.cassette          == @targ_vec.cassette           \
        and @mol_struct.backbone          == @targ_vec.backbone)
          # Delete molecular structure if created in this process
          @mol_struct.delete if mol_struct_created
          
          errors << { "ES Cell is invalid" =>
            "targeting vector's molecular structure should be similar to molecular structure hash provided."
          }
        end
      
      # CREATE targeting vector from hash
      elsif es_cell_hash.include? :targeting_vector
        targ_vec_created = true
        targ_vec_hash = es_cell_hash[:targeting_vector]
        
        # Update targ_vec_hash with provided molecular structure id if it has
        # not got one yet.
        unless targ_vec_hash.include? :molecular_structure_id
          targ_vec_hash.update({ :molecular_structure_id => @mol_struct.id })
        end
        
        @targ_vec = TargetingVector.new( es_cell_hash[:targeting_vector] )
        unless @targ_vec.save
          # Delete molecular structure if created in this process
          @mol_struct.delete if mol_struct_created
          
          errors << { "Targeting Vector is invalid" => @targ_vec.errors }
        end
      end
    end
    
    
    #
    # Create ES Cell
    #
    
    if errors.empty?
      es_cell_hash.delete( :targeting_vector )
      es_cell_hash.delete( :molecular_structure )
      es_cell_hash[:targeting_vector_id]    = @targ_vec.id    if @targ_vec
      es_cell_hash[:molecular_structure_id] = @mol_struct.id  if @mol_struct
      
      @es_cell = EsCell.new( es_cell_hash )
      unless @es_cell.save
        # Delete molecular structure and/or targeting vector
        # if created in this process
        @mol_struct.delete  if mol_struct_created
        @targ_vec.delete    if targ_vec_created
        errors << { "ES Cell is invalid" => @es_cell.errors }
      end
    end
    
    respond_to do |format|
      if errors.empty?
        format.xml  { render :xml  => @es_cell, :status => :created, :location => @es_cell }
        format.json { render :json => @es_cell, :status => :created, :location => @es_cell }
      else
        format.xml  { render :xml  => errors.to_xml, :status => 400 }
        format.json { render :json => errors.to_json, :status => 400 }
      end
    end
  end

  # PUT /es_cells/1.xml
  # PUT /es_cells/1.json
  def update
    respond_to do |format|
      if @es_cell.update_attributes(params[:es_cell])
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.xml  { render :xml  => @es_cell.errors, :status => :unprocessable_entity }
        format.json { render :json => @es_cell.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /es_cells/1.xml
  # DELETE /es_cells/1.json
  def destroy
    @es_cell.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  private
    def find_escell # makes our views "cleaner" and more consistent
      @es_cell = EsCell.find(params[:id])
    end
end
