class MolecularStructuresController < ApplicationController
  before_filter :require_user, :only => [:create, :edit, :update, :destroy]
  before_filter :find_molecular_structures, :only => :index
  before_filter :find_molecular_structure,
    :only => [
      :show, :edit, :update, :destroy, 
      :get_escell_clone_genbank_file,
      :get_targeting_vector_genbank_file,
      :get_allele_image
    ]
  
  # Following both are located in application_controller.rb
  before_filter :set_created_by, :only => :create
  before_filter :set_updated_by, :only => :update
  
  # For webservice interface
  before_filter :format_nested_params, :only => [:create, :update]
  
  # GET /molecular_structures
  # GET /molecular_structures.xml
  # GET /molecular_structures.json
  def index
    @molecular_structures = @search.all( :include => :pipeline ).paginate(:page => params[:page])
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml   => @molecular_structures }
      format.json { render :json  => @molecular_structures }
    end
  end

  # GET /molecular_structures/1
  # GET /molecular_structures/1.xml
  # GET /molecular_structures/1.json
  def show
    @es_cells = @molecular_structure.es_cells.find(:all, :order => "name")
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml   => @molecular_structure }
      format.json { render :json  => @molecular_structure }
    end
  end

  # GET /molecular_structures/new
  def new
    @molecular_structure = MolecularStructure.new
    @molecular_structure.genbank_file = GenbankFile.new
    @molecular_structure.targeting_vectors.build
    @molecular_structure.es_cells.build
  end

  # GET /molecular_structures/1/edit
  def edit
    if @molecular_structure.genbank_file.nil?
      @molecular_structure.genbank_file = GenbankFile.new
    end
  end

  # POST /molecular_structures
  # POST /molecular_structures.xml
  # POST /molecular_structures.json
  def create
    @molecular_structure = MolecularStructure.new( params[:molecular_structure] )
    
    respond_to do |format|
      if @molecular_structure.save
        # Useful for all formats, not only HTML
        update_links_escell_to_targ_vec( @molecular_structure.id, params[:molecular_structure] )
        
        format.html {
          flash[:notice] = 'Allele successfully created.'
          redirect_to @molecular_structure
        }
        format.xml  { render :xml  => @molecular_structure, :status => :created, :location => @molecular_structure }
        format.json { render :json => @molecular_structure, :status => :created, :location => @molecular_structure }
      else
        format.html {
          @molecular_structure.genbank_file = GenbankFile.new
          render :action => "new"
        }
        format.xml  { render :xml  => @molecular_structure.errors, :status => :unprocessable_entity }
        format.json { render :json => @molecular_structure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /molecular_structures/1
  # PUT /molecular_structures/1.xml
  def update
    respond_to do |format|
      if @molecular_structure.update_attributes(params[:molecular_structure])
        # Useful for all formats, not only HTML
        update_links_escell_to_targ_vec( @molecular_structure.id, params[:molecular_structure] )
        
        format.html {
          flash[:notice] = 'Allele successfully updated.'
          redirect_to @molecular_structure 
        }
        format.xml  { render :xml  => @molecular_structure }
        format.json { render :json => @molecular_structure }
      else
        format.html {
          if @molecular_structure.genbank_file.nil?
            @molecular_structure.genbank_file = GenbankFile.new
          end
          render :action => "edit"
        }
        format.xml  { render :xml   => @molecular_structure.errors, :status => :unprocessable_entity }
        format.json { render :json  => @molecular_structure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /molecular_structures/1
  # DELETE /molecular_structures/1.xml
  def destroy
    @molecular_structure.destroy

    respond_to do |format|
      format.html { redirect_to(molecular_structures_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
  
  ##
  ## Custom controllers
  ##
  
  # GET /molecular_structures/1/escell-clone-genbank-file/
  def get_escell_clone_genbank_file
    render :inline => "<pre><%= @molecular_structure.genbank_file.escell_clone %></pre>"
  end

  # GET /molecular_structures/1/targeting-vector-genbank-file/
  def get_targeting_vector_genbank_file
    render :inline => "<pre><%= @molecular_structure.genbank_file.targeting_vector %></pre>"
  end

  # GET /molecular_structures/1/allele-image/
  def get_allele_image
    send_data(
      AlleleImage::Image.new( @molecular_structure.genbank_file.escell_clone ).render.to_blob { self.format = "PNG" }, 
        :disposition => "inline",
        :type => "image/png"
    )
  end

  private
    def find_molecular_structure
      @molecular_structure = MolecularStructure.find(params[:id])
    end
    
    def find_molecular_structures
      mol_struct_params = params.dup
      
      # Just keep Molecular Structure params.
      mol_struct_params.delete( "controller" )
      mol_struct_params.delete( "action" )
      mol_struct_params.delete( "format" )
      mol_struct_params.delete( "page" )
      
      if mol_struct_params.include? :search
        mol_struct_params = params[:search]
      elsif mol_struct_params[ :loxp_start ] == 'null' and mol_struct_params[ :loxp_end ] == 'null'
        # 'loxp_start_null' and 'loxp_end_null' should be used to force
        # these fields to be null
        mol_struct_params.delete( :loxp_start )
        mol_struct_params.delete( :loxp_end )
        mol_struct_params.update({
          :loxp_start_null  => true,
          :loxp_end_null    => true
        })
      end
      
      @search = MolecularStructure.search( mol_struct_params )
    end
    
    def format_nested_params
      # Specific to create/update methods - webservice interface
      mol_struct_params = params[ :molecular_structure ]
      
      # README: http://github.com/dazoakley/targ_rep2/issues#issue/1
      #
      # ``accepts_nested_attributes_for`` (in model.rb) expects 
      # <child_model>_attributes as a key in params hash in order to 
      # create <child_model> objects.
      # For now, it is allowed to send a nested Array such as ``es_cells``
      # instead of the expected ``es_cell_attributes`` Array.
      # This function will rename/move ``es_cells`` to ``es_cell_attributes``.
      #
      # Because of the rails issue (see ticket):
      # This function will also add the ``nested => true`` key/value pair to each 
      # hash contained in the Array so that the model does not try to validate
      # the ES Cell before the molecular structure gets its ID (creation only).
      
      ##
      ##  ES Cells
      ##
      
      if mol_struct_params.include? :es_cells
        mol_struct_params[:es_cells].each { |attrs| attrs[:nested] = true }
        mol_struct_params[:es_cells_attributes] = mol_struct_params.delete(:es_cells)
      
      elsif not mol_struct_params.include? :es_cells_attributes
        mol_struct_params[:es_cells_attributes] = []
      end
      
      
      ##
      ##  Targeting Vectors + their ES Cells
      ##
      
      if mol_struct_params.include? :targeting_vectors
        mol_struct_params[:targeting_vectors].each do |attrs|
          attrs.update({ :nested => true })
          
          # Move ``es_cells`` Array related to this Targeting Vector
          # into the ``es_cells_attributes`` Array created above.
          # es_cell hash will contain targeting_vector_name so that it can be
          # related to the proper targeting_vector when it gets an ID.
          if attrs.include? :es_cells
            attrs[:es_cells].each do |es_cell_attr|
              es_cell_attr.update({
                :nested => true,
                :targeting_vector_name => attrs[:name]
              })
              mol_struct_params[:es_cells_attributes].push( es_cell_attr )
            end
            attrs.delete( :es_cells )
          end
        end
        
        mol_struct_params[:targeting_vectors_attributes] = mol_struct_params.delete(:targeting_vectors)
      end
      
      
      ##
      ##  Genbank Files
      ##
      
      if mol_struct_params.include? :genbank_file
        mol_struct_params[:genbank_file].update({ :nested => true })
        mol_struct_params[:genbank_file_attributes] = mol_struct_params.delete(:genbank_file)
      end
      
      # Don't create genbank file object if its attributes are empty.
      gb_files_attrs = mol_struct_params[:genbank_file_attributes]
      if gb_files_attrs
        gb_escell = gb_files_attrs[:escell_clone]
        gb_targ_vec = gb_files_attrs[:targeting_vector]
        
        if gb_escell.nil? and gb_targ_vec.nil?
          mol_struct_params.delete(:genbank_file_attributes)
        elsif !gb_escell.nil? and !gb_targ_vec.nil? \
          and gb_escell.empty? and gb_targ_vec.empty?
          mol_struct_params.delete(:genbank_file_attributes)
        end
      end
    end
    
    # One can give a targeting_vector_name instead of a targeting_vector_id
    # to link an ES Cell to its Targeting Vector.
    # This function will find the right targeting vector from the given name
    def update_links_escell_to_targ_vec( mol_struct_id, params )
      return unless params.include? :es_cells_attributes
      
      es_cells_attrs = []
      if params[:es_cells_attributes].is_a? Array
        params[:es_cells_attributes].each do |attrs|
          es_cells_attrs.push( attrs )
        end
      else
        params[:es_cells_attributes].each do |key, attrs|
          es_cells_attrs.push( attrs )
        end
      end
      
      es_cells_attrs.each do |attrs|
        if attrs.include? :targeting_vector_name
          
          # Find ES Cell from its 'id' or its 'name' + 'molecular_structure_id'
          if attrs.include? :id
            es_cell = EsCell.find( attrs[:id] )
          else
            search = EsCell.search({
              :name_like                 => attrs[:name],
              :molecular_structure_id_is => mol_struct_id
            })
            es_cell = search.first
          end
          
          # Find targeting vector from given name and link it to the ES Cell
          if es_cell and es_cell.targeting_vector.nil?
            search = TargetingVector.name_is(attrs[:targeting_vector_name])
            es_cell.targeting_vector = search.first
            es_cell.save
          end
        end
      end
    end
end
