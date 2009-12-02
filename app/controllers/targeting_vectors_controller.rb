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
  def create
    @targeting_vector = TargetingVector.new(params[:targeting_vector])

    respond_to do |format|
      if @targeting_vector.save
        format.xml  { render :xml => @targeting_vector, :status => :created, :location => @targeting_vector }
      else
        format.xml  { render :xml => @targeting_vector.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /targeting_vectors/1.xml
  def update
    respond_to do |format|
      if @targeting_vector.update_attributes(params[:targeting_vector])
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @targeting_vector.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /targeting_vectors/1.xml
  def destroy
    @targeting_vector.destroy

    respond_to do |format|
      format.xml  { head :ok }
    end
  end
  
  private
    def find_targ_vec
      @targeting_vector = TargetingVector.find(params[:id])
    end
end
