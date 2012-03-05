class EsCellsController < ApplicationController
  before_filter :find_escell, :only => [:show, :update, :destroy]
  before_filter :find_escells, :only => :index

  # Must be after "find_escell" filter (as it requires an object)
  before_filter :ensure_creator_or_admin, :only => [:destroy]

  # The following are located in application_controller.rb
  before_filter :get_qc_field_descriptions, :only => [:bulk_edit, :update_multiple]

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
        format.xml  { render :xml  => @es_cell, :location => @es_cell }
        format.json { render :json => @es_cell, :location => @es_cell }
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

  # GET /es_cells/bulk_edit
  # POST /es_cells/bulk_edit
  def bulk_edit
    unless params[:es_cell_names].nil?
      es_cell_names = params[:es_cell_names].split("\n").map{ |elm| rv = elm.chomp ; rv.strip! || rv }.compact
      @es_cells     = EsCell.all( :conditions => { :name => es_cell_names } )
      @es_cells.sort!{ |a,b| es_cell_names.index(a.name) <=> es_cell_names.index(b.name) }
    end
  end

  # PUT /es_cells/update_multiple
  def update_multiple
    @es_cells = EsCell.update( params[:es_cells].keys, params[:es_cells].values ).reject { |p| p.errors.empty? }

    if @es_cells.empty?
      flash[:notice] = "ES Cells Updated"
      redirect_to :action => :bulk_edit
    else
      flash[:error] = "There was a problem updating some of your records - the failed entries are shown below"
      render :action => :bulk_edit
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
