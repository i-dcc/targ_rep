class TargetingVectorsController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_targ_vec, :only => [:show, :update, :destroy]
  
  # GET /targeting_vectors.js
  # GET /targeting_vectors.xml
  # GET /targeting_vectors.json
  def index
    search = TargetingVector.search
    search.molecular_structure_mgi_accession_id_equals( params[:mgi_accession_id]) unless params[:mgi_accession_id].blank?
    search.name_like( params[:name] ) unless params[:name].blank?
    @targeting_vectors = search.find( :all )
    
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
    
    respond_to do |format|
      # Create molecular structure if details are given in params
      if targ_vec_hash[:molecular_structure]
        @molecular_structure = MolecularStructure.new(targ_vec_hash[:molecular_structure])
        targ_vec_hash.delete(:molecular_structure)
        
        if @molecular_structure.save          
          targ_vec_hash.update({ 
            :molecular_structure_id => @molecular_structure.id
          })
        else
          targ_vec_hash.update({ 
            :molecular_structure_id => nil
          })
        end
      end
      
      # Create targeting vector - expecting a molecular_structure_id anyway
      @targeting_vector = TargetingVector.new( targ_vec_hash )
      if @targeting_vector.save
        _success(format)
      else
        @molecular_structure.delete if @molecular_structure
        _error(format)
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
        _error(format)
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

    def _success(format)
      format.xml  { render :xml  => @targeting_vector, :status => :created, :location => @targeting_vector }
      format.json { render :json => @targeting_vector, :status => :created, :location => @targeting_vector }
    end
    
    def _error(format)
      format.xml  { render :xml  => @targeting_vector.errors, :status => :unprocessable_entity }
      format.json { render :json => @targeting_vector.errors, :status => :unprocessable_entity }
    end
end
