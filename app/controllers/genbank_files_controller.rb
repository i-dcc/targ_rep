class GenbankFilesController < ApplicationController
  before_filter :find_genbank_file, :only => [:show, :update, :destroy]

  # Must be after "find_genbank_file" filter (as it requires an object)
  # FIXME: Genbank File must have a 'created_by' field for this filter to run
  # before_filter :ensure_creator_or_admin, :only => [:destroy]
  
  def index
    respond_to do |format|
      if params.key? :molecular_structure_id
        @genbank_file = GenbankFile.search(:molecular_structure_id => params[:molecular_structure_id]).all
        format.xml  { render :xml   => @genbank_file }
        format.json { render :json  => @genbank_file }
      else
        errors = { :molecular_structure_id => "is required" }
        format.xml  { render :xml   => errors, :status => :unprocessable_entity }
        format.json { render :json  => errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # GET /genbank_files/1.xml
  # GET /genbank_files/1.json
  def show
    respond_to do |format|
      format.xml  { render :xml  => @genbank_file }
      format.json { render :json => @genbank_file }
    end
  end

  # POST /genbank_files.xml
  # POST /genbank_files.json
  def create
    @genbank_file = GenbankFile.new(params[:genbank_file])

    respond_to do |format|
      if @genbank_file.save
        format.xml  { render :xml  => @genbank_file, :status => :created, :location => @genbank_file }
        format.json { render :json => @genbank_file, :status => :created, :location => @genbank_file }
      else
        format.xml  { render :xml  => @genbank_file.errors, :status => :unprocessable_entity }
        format.json { render :json => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /genbank_files/1.xml
  def update
    respond_to do |format|
      if @genbank_file.update_attributes(params[:genbank_file])
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.xml  { render :xml  => @genbank_file.errors, :status => :unprocessable_entity }
        format.json { render :json => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /genbank_files/1.xml
  # DELETE /genbank_files/1.json
  def destroy
    @genbank_file.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  private
    def find_genbank_file # makes our views "cleaner" and more consistent
      @genbank_file = GenbankFile.find(params[:id])
    end
end
