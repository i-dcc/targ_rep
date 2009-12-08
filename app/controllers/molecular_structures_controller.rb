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
    @molecular_structures = MolecularStructure.all.paginate(:page => params[:page])

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
  def create
    @molecular_structure = MolecularStructure.new(params[:molecular_structure])

    respond_to do |format|
      if @molecular_structure.save
        flash[:notice] = 'Allele successfully created.'
        format.html { redirect_to @molecular_structure }
        format.xml  { render :xml  => @molecular_structure, :status => :created, :location => @molecular_structure }
        format.json { render :json => @molecular_structure, :status => :created, :location => @molecular_structure }
      else
        format.html { 
          @molecular_structure.genbank_file = GenbankFile.new
          render :action => "new" 
        }
        format.xml  { render :xml  => @molecular_structure.errors, :status => :unprocessable_entity }
        format.xml  { render :json => @molecular_structure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /molecular_structures/1
  # PUT /molecular_structures/1.xml
  def update
    respond_to do |format|
      if @molecular_structure.update_attributes(params[:molecular_structure])
        flash[:notice] = 'Allele successfully updated.'
        format.html { redirect_to @molecular_structure }
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
end
