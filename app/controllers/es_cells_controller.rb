class EsCellsController < ApplicationController
  before_filter :find_escell, :only => [:show, :update, :destroy]
  before_filter :find_escells, :only => :index
  
  # Must be after "find_escell" filter (as it requires an object)
  before_filter :ensure_permission, :only => [:update, :destroy]
  
  # Following both are located in application_controller.rb
  before_filter :set_created_by, :only => :create
  before_filter :set_updated_by, :only => :update
  
  # GET /es_cells.xml
  # GET /es_cells.json
  def index
    @es_cells = @search.all()
    
    respond_to do |format|
      format.xml  { render :xml   => @es_cells }
      format.json { render :json  => @es_cells }
    end
  end

  # GET /es_cells/1.xml
  # GET /es_cells/1.json
  def show
    respond_to do |format|
      format.xml  { render :xml   => @es_cell }
      format.json { render :json  => @es_cell }
    end
  end

  # POST /es_cells.xml
  # POST /es_cells.json
  def create
    @es_cell = EsCell.new( params[:es_cell] )
    
    respond_to do |format|
      if @es_cell.save
        format.xml  { render :xml  => @es_cell, :status => :created, :location => @es_cell }
        format.json { render :json => @es_cell, :status => :created, :location => @es_cell }
      else
        format.xml  { render :xml  => @es_cell.errors, :status => 400 }
        format.json { render :json => @es_cell.errors, :status => 400 }
      end
    end
  end

  # PUT /es_cells/1.xml
  # PUT /es_cells/1.json
  def update
    respond_to do |format|
      if @es_cell.update_attributes( params[:es_cell] )
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.xml  { render :xml  => @es_cell.errors, :status => 400 }
        format.json { render :json => @es_cell.errors, :status => 400 }
      end
    end
  end

  # DELETE /es_cells/1.xml
  # DELETE /es_cells/1.json
  def destroy
    @es_cell.destroy

    respond_to do |format|
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  private
    def find_escell # makes our views "cleaner" and more consistent
      @es_cell = EsCell.find(params[:id])
    end

    def find_escells
      escell_params = params.dup

      # Just keep TargetingVector params.
      escell_params.delete( "controller" )
      escell_params.delete( "action" )
      escell_params.delete( "format" )
      escell_params.delete( "page" )

      @search = EsCell.search( escell_params )
    end
end
