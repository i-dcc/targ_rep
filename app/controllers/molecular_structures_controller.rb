class MolecularStructuresController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_mol_struct, :only => [:show, :edit, :update, :destroy]
  
  # GET /molecular_structures
  # GET /molecular_structures.xml
  def index
    @molecular_structures = MolecularStructure.all.paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @molecular_structures }
    end
  end

  # GET /molecular_structures/1
  # GET /molecular_structures/1.xml
  def show
  end

  # GET /molecular_structures/new
  # GET /molecular_structures/new.xml
  def new
    @molecular_structure = MolecularStructure.new
    @molecular_structure.targeting_vectors.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @molecular_structure }
    end
  end

  # GET /molecular_structures/1/edit
  def edit
  end

  # POST /molecular_structures
  # POST /molecular_structures.xml
  def create
    @molecular_structure = MolecularStructure.new(params[:molecular_structure])

    respond_to do |format|
      if @molecular_structure.save
        flash[:notice] = 'Allele successfully created.'
        format.html { redirect_to(@molecular_structure) }
        format.xml  { render :xml => @molecular_structure, :status => :created, :location => @molecular_structure }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @molecular_structure.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /molecular_structures/1
  # PUT /molecular_structures/1.xml
  def update
    params[:molecular_structure][:update_targeting_vectors] ||= {}
    
    respond_to do |format|
      if @molecular_structure.update_attributes(params[:molecular_structure])
        flash[:notice] = 'Allele successfully updated.'
        format.html { redirect_to(@molecular_structure) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @molecular_structure.errors, :status => :unprocessable_entity }
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
    end
  end
  
  private
  def find_mol_struct
    @molecular_structure = MolecularStructure.find(params[:id])
  end
end
