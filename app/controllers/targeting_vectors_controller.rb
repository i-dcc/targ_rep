class TargetingVectorsController < ApplicationController
  before_filter :find_targ_vec, :only => [:show, :update, :destroy]
  before_filter :find_targeting_vectors, :only => :index
  
  # Must be after "find_targ_vec" filter (as it requires an object)
  before_filter :ensure_permission, :only => [:update, :destroy]
  
  # Following both are located in application_controller.rb
  before_filter :set_created_by, :only => :create
  before_filter :set_updated_by, :only => :update
  
  # For webservice interface
  before_filter :format_nested_params, :only => [:create, :update]
  
  # GET /targeting_vectors.js
  # GET /targeting_vectors.xml
  # GET /targeting_vectors.json
  def index
    @targeting_vectors = @search.all()
    
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
    @targeting_vector = TargetingVector.new( params[:targeting_vector] )
    
    respond_to do |format|
      if @targeting_vector.save
        format.xml  { render :xml  => @targeting_vector, :status => :created, :location => @targeting_vector }
        format.json { render :json => @targeting_vector, :status => :created, :location => @targeting_vector }
      else
        format.xml  { render :xml  => @targeting_vector.errors, :status => 400, :location => @targeting_vector }
        format.json { render :json => @targeting_vector.errors, :status => 400, :location => @targeting_vector }
      end
    end
  end

  # PUT /targeting_vectors/1.xml
  # PUT /targeting_vectors/1.json
  def update
    respond_to do |format|
      if @targeting_vector.update_attributes( params[:targeting_vector] )
        format.xml  { render :xml  => @targeting_vector, :status => :ok, :location => @targeting_vector }
        format.json { render :json => @targeting_vector, :status => :ok, :location => @targeting_vector }
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
    
    def find_targeting_vectors
      targ_vec_params = params.dup
      
      # Just keep TargetingVector params.
      targ_vec_params.delete( "controller" )
      targ_vec_params.delete( "action" )
      targ_vec_params.delete( "format" )
      targ_vec_params.delete( "page" )
      
      @search = TargetingVector.search( targ_vec_params )
    end
    
    def format_nested_params
      # Specific to create/update methods - webservice interface
      targ_vec_params = params[ :targeting_vector ]
      
      # README: http://github.com/dazoakley/targ_rep2/issues#issue/1
      #
      # ``accepts_nested_attributes_for`` (in model.rb) expects 
      # es_cell_attributes as a key in params hash in order to 
      # create ES cell objects.
      # For now, it is allowed to send a nested Array such as ``es_cells``
      # instead of the expected ``es_cell_attributes`` Array.
      # This function will rename/move ``es_cells`` to ``es_cell_attributes``.
      #
      # Because of the rails issue (see ticket):
      # This function will also add the ``nested => true`` key/value pair to each
      # hash contained in the Array so that the model does not try to validate
      # the ES Cell before the targeting vector gets its ID (creation only).
      
      if targ_vec_params.include? :es_cells
        targ_vec_params[:es_cells].each { |attrs| attrs[:nested] = true }
        targ_vec_params[:es_cells_attributes] = targ_vec_params.delete(:es_cells)
      elsif not targ_vec_params.include? :es_cells_attributes
        targ_vec_params[:es_cells_attributes] = []
      end
    end
end
