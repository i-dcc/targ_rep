class GenbankFilesController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_genbank_file, :only => [:show, :edit, :update, :destroy]
  
  # GET /genbank_files
  # GET /genbank_files.xml
  def index
    @genbank_files = GenbankFile.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @genbank_files }
    end
  end

  # GET /genbank_files/1
  # GET /genbank_files/1.xml
  def show
  end

  # GET /genbank_files/new
  # GET /genbank_files/new.xml
  def new
    @genbank_file = GenbankFile.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @genbank_file }
    end
  end

  # GET /genbank_files/1/edit
  def edit
  end

  # POST /genbank_files
  # POST /genbank_files.xml
  def create
    @genbank_file = GenbankFile.new(params[:genbank_file])

    respond_to do |format|
      if @genbank_file.save
        flash[:notice] = 'GenbankFile was successfully created.'
        format.html { redirect_to(@genbank_file) }
        format.xml  { render :xml => @genbank_file, :status => :created, :location => @genbank_file }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /genbank_files/1
  # PUT /genbank_files/1.xml
  def update
    respond_to do |format|
      if @genbank_file.update_attributes(params[:genbank_file])
        flash[:notice] = 'GenbankFile was successfully updated.'
        format.html { redirect_to(@genbank_file) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /genbank_files/1
  # DELETE /genbank_files/1.xml
  def destroy
    @genbank_file.destroy

    respond_to do |format|
      format.html { redirect_to(genbank_files_url) }
      format.xml  { head :ok }
    end
  end

  private
    def find_genbank_file # makes our views "cleaner" and more consistent
      @genbank_file = GenbankFile.find(params[:id])
    end
end
