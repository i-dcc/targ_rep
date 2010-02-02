class MolecularStructuresController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_mol_struct, 
    :only => [
      :show, :edit, :update, :destroy, 
      :get_escell_clone_genbank_file,
      :get_targeting_vector_genbank_file
    ]
  
  # GET /molecular_structures
  # GET /molecular_structures.xml
  # GET /molecular_structures.json
  def index
    mol_struct_params = params.dup
    
    # Just keep params that are Molecular Structure attributes. 
    # A molecular structure will be search from this params
    mol_struct_params.delete( "controller" )
    mol_struct_params.delete( "action" )
    mol_struct_params.delete( "format" )
    mol_struct_params.delete( "page" )
    
    if mol_struct_params.nil? or mol_struct_params.empty?
      @molecular_structures = MolecularStructure.all.paginate(:page => params[:page])
    else
      if mol_struct_params[ :loxp_start ] == 'null' and mol_struct_params[ :loxp_end ] == 'null'
        # If you don't delete these, it will try to search with loxp_start = 0
        # instead of loxp_start IS NULL
        mol_struct_params.delete( :loxp_start )
        mol_struct_params.delete( :loxp_end )
        
        # Don't break this line in multiple lines or you will get a wrong result
        search = MolecularStructure.loxp_start_null.loxp_end_null.search( mol_struct_params )
      else
        search = MolecularStructure.search( mol_struct_params )
      end
      
      @molecular_structures = search.paginate(:page => params[:page])
    end
    
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
  # For the ``nested`` attribute appended to the hash, have a look here:
  # http://github.com/dazoakley/targ_rep2/issues#issue/1
  def create
    mol_struct_params = params[:molecular_structure]
    
    # Start: web service interface
    
    # Rails helper:
    # ``accepts_nested_attributes_for`` expects <child_model>_attributes as a 
    # key in params hash to create <child_model> objects.
    
    # Move ``es_cells`` to ``es_cells_attributes``
    if mol_struct_params.include? :es_cells
      mol_struct_params[:es_cells].each { |attrs| attrs[:nested] = true }
      mol_struct_params[:es_cells_attributes] = mol_struct_params[:es_cells].dup
      mol_struct_params.delete(:es_cells)
    elsif !mol_struct_params.include? :es_cells_attributes
      mol_struct_params[:es_cells_attributes] = []
    end
    
    # Move ``targeting_vectors`` to ``targeting_vectors_attributes``
    if mol_struct_params.include? :targeting_vectors
      mol_struct_params[:targeting_vectors].each do |attrs|
        attrs.update({ :nested => true })
        
        # Copy es_cells Array related to this Targeting Vector
        # into the es_cells_attributes Array created above.
        # es_cell hash will contain targeting_vector_name so that it can be
        # related to the proper targeting_vector later - once it gets an ID.
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
      mol_struct_params[:targeting_vectors_attributes] = mol_struct_params[:targeting_vectors].dup
      mol_struct_params.delete(:targeting_vectors)
    end
    
    # Move ``genbank_file`` to ``genbank_file_attributes``
    if mol_struct_params.include? :genbank_file
      mol_struct_params[:genbank_file].update({ :nested => true })
      mol_struct_params[:genbank_file_attributes] = mol_struct_params[:genbank_file].dup
      mol_struct_params.delete(:genbank_file)
    end
    
    # End: web service interface
    
    @molecular_structure = MolecularStructure.new( mol_struct_params )
    respond_to do |format|
      if @molecular_structure.save
        update_links_escell_to_targ_vec( @molecular_structure.id, mol_struct_params )
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
    mol_struct_params = params[:molecular_structure]
    
    # Genbank file handling
    if mol_struct_params.include? :genbank_file and mol_struct_params[:genbank_file].empty?
      mol_struct_params.delete :genbank_file
    elsif mol_struct_params.include? :genbank_file
      mol_struct_params[:genbank_file].update({ :nested => true })
      mol_struct_params[:genbank_file_attributes] = mol_struct_params[:genbank_file].dup
      mol_struct_params.delete :genbank_file
    end
    
    # Targeting vectors handling - TODO
    if mol_struct_params.include? :targeting_vectors and mol_struct_params[:targeting_vectors].empty?
      mol_struct_params.delete :targeting_vectors
    end
    
    # ES Cells handling - TODO
    if mol_struct_params.include? :es_cells and mol_struct_params[:es_cells].empty?
      mol_struct_params.delete :es_cells
    end
    
    respond_to do |format|
      if @molecular_structure.update_attributes(params[:molecular_structure])
        format.html {
          update_links_escell_to_targ_vec( @molecular_structure.id, params[:molecular_structure] )
          flash[:notice] = 'Allele successfully updated.'
          redirect_to @molecular_structure }
        format.xml  { head :ok }
        format.json { head :ok }
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
  
  #--- Custom controllers
  # FIXME: Ugly way of retrieving genbank files. Use nice routing instead
  # GET /molecular_structures/1/escell-clone-genbank-file/
  def get_escell_clone_genbank_file
    render :inline => "<pre><%= @molecular_structure.genbank_file.escell_clone %></pre>"
  end

  # GET /molecular_structures/1/targeting-vector-genbank-file/
  def get_targeting_vector_genbank_file
    render :inline => "<pre><%= @molecular_structure.genbank_file.targeting_vector %></pre>"
  end

  private
  def find_mol_struct
    @molecular_structure = MolecularStructure.find(params[:id])
  end
  
  # When trying to create a new targeting vector and link it at the
  # same time to an ES Cell via its name, it won't work properly.
  # Following is a fix to this problem - specific to HTML pages
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
        # Find ES Cell
        if attrs.include? :id
          es_cell = EsCell.find attrs[:id]
        else
          search = EsCell.search
          search.name_like = attrs[:name]
          search.molecular_structure_id_is = mol_struct_id
          es_cell = search.first
        end
        
        # If ES Cell is not related to a targeting vector though a
        # targeting vector name has been provided, let's find the targ
        # vector and link it to the ES Cell
        if es_cell and es_cell.targeting_vector.nil?
          search = TargetingVector.name_is(attrs[:targeting_vector_name])
          es_cell.targeting_vector = search.first
          es_cell.save
        end
      end
    end
  end
end
