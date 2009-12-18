class TargetingVectorsController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_targ_vec, :only => [:show, :update, :destroy]
  
  # GET /targeting_vectors.js
  # GET /targeting_vectors.xml
  # GET /targeting_vectors.json
  def index
    targ_vec_params = params.dup
    
    # Just keep params that are Molecular Structure attributes. 
    # A molecular structure will be search from this params
    targ_vec_params.delete( "controller" )
    targ_vec_params.delete( "action" )
    targ_vec_params.delete( "format" )
    targ_vec_params.delete( "page" )
    
    @targeting_vectors = TargetingVector.search( targ_vec_params ).all
    
    respond_to do |format|
      format.js # index.js.erb
      format.xml  { render :xml   => @targeting_vectors }
      format.json { render :json  => @targeting_vectors }
    end
  end

  # GET /targeting_vectors/1.xml
  # GET /targeting_vectors/1.json
  def show
    respond_to do |format|
      format.xml  { render :xml   => @targeting_vector }
      format.json { render :json  => @targeting_vector }
    end
  end

  # POST /targeting_vectors.xml
  # POST /targeting_vectors.json
  def create
    targ_vec_hash = params[:targeting_vector]
    
    errors = []
    
    #
    # Basic checks
    #
    
    if targ_vec_hash.include? :molecular_structure and targ_vec_hash.include? :molecular_structure_id
      errors << { "Targeting vector is invalid" =>
        "should have only one molecular structure representation (id or hash)"
      }
      targ_vec_hash.delete( :molecular_structure )
    
    elsif !targ_vec_hash.include? :molecular_structure and !targ_vec_hash.include? :molecular_structure_id
      errors << { "Targeting vector is invalid" =>
        "should have at least one molecular structure representation (id or hash)"
      }
    end
    
    #
    # Create molecular structure
    #
    
    if targ_vec_hash.include? :molecular_structure
      mol_struct = MolecularStructure.new( targ_vec_hash[:molecular_structure] )
      
      if mol_struct.save
        targ_vec_hash.delete( :molecular_structure )
        targ_vec_hash.update( { :molecular_structure_id => mol_struct.id } )
      else
        errors << { "Molecular Structure is invalid" => mol_struct.errors }
      end
    end
    
    #
    # Create targeting vector
    #
    
    if errors.empty?
      # molecular_structure_id should be in targ_vec_hash anyway
      @targeting_vector = TargetingVector.new( targ_vec_hash )
      
      unless @targeting_vector.save
        mol_struct.delete if mol_struct
        errors << { "Targeting Vector is invalid" => @targeting_vector.errors }
      end
    end
    
    respond_to do |format|
      if errors.empty?
        format.xml  { render :xml  => @targeting_vector, :status => :created, :location => @targeting_vector }
        format.json { render :json => @targeting_vector, :status => :created, :location => @targeting_vector }
      else
        format.xml  { render :xml  => errors, :status => 400, :location => @targeting_vector }
        format.json { render :json => errors, :status => 400, :location => @targeting_vector }
      end
    end
  end

  # PUT /targeting_vectors/1.xml
  # PUT /targeting_vectors/1.json
  def update
    respond_to do |format|
      if @targeting_vector.update_attributes(params[:targeting_vector])
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.xml  { render :xml  => @targeting_vector.errors, :status => :unprocessable_entity }
        format.json { render :json => @targeting_vector.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /targeting_vectors/1.xml
  # DELETE /targeting_vectors/1.json
  def destroy
    @targeting_vector.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
  
  private
    def find_targ_vec
      @targeting_vector = TargetingVector.find(params[:id])
    end
end
