class GenbankFilesController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_genbank_file, :only => [:show, :update, :destroy]
  
  # GET /genbank_files/1.xml
  def show
    respond_to do |format|
      format.xml  { render :xml => @genbank_file }
    end
  end

  # POST /genbank_files.xml
  def create
    @genbank_file = GenbankFile.new(params[:genbank_file])

    respond_to do |format|
      if @genbank_file.save
        format.xml  { render :xml => @genbank_file, :status => :created, :location => @genbank_file }
      else
        format.xml  { render :xml => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /genbank_files/1.xml
  def update
    respond_to do |format|
      if @genbank_file.update_attributes(params[:genbank_file])
        format.xml  { head :ok }
      else
        format.xml  { render :xml => @genbank_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /genbank_files/1
  # DELETE /genbank_files/1.xml
  def destroy
    @genbank_file.destroy

    respond_to do |format|
      format.xml  { head :ok }
    end
  end

  private
    def find_genbank_file # makes our views "cleaner" and more consistent
      @genbank_file = GenbankFile.find(params[:id])
    end
end
