class EsCellsController < ApplicationController
  before_filter :require_user, :only => [:create, :update, :destroy]
  before_filter :find_escell, :only => [:show, :edit, :update, :destroy]
  
  # GET /es_cells
  # GET /es_cells.xml
  def index
    @es_cells = EsCell.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @es_cells }
    end
  end

  # GET /es_cells/1
  # GET /es_cells/1.xml
  def show
  end

  # GET /es_cells/new
  # GET /es_cells/new.xml
  def new
    @es_cell = EsCell.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @es_cell }
    end
  end

  # GET /es_cells/1/edit
  def edit
  end

  # POST /es_cells
  # POST /es_cells.xml
  def create
    @es_cell = EsCell.new(params[:es_cell])

    respond_to do |format|
      if @es_cell.save
        flash[:notice] = 'EsCell was successfully created.'
        format.html { redirect_to(@es_cell) }
        format.xml  { render :xml => @es_cell, :status => :created, :location => @es_cell }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @es_cell.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /es_cells/1
  # PUT /es_cells/1.xml
  def update
    respond_to do |format|
      if @es_cell.update_attributes(params[:es_cell])
        flash[:notice] = 'EsCell was successfully updated.'
        format.html { redirect_to(@es_cell) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @es_cell.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /es_cells/1
  # DELETE /es_cells/1.xml
  def destroy
    @es_cell.destroy

    respond_to do |format|
      format.html { redirect_to(es_cells_url) }
      format.xml  { head :ok }
    end
  end

  private
    def find_escell # makes our views "cleaner" and more consistent
      @es_cell = EsCell.find(params[:id])
    end
end
