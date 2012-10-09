
require 'pp'

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

    @bulk_edit = true

    unless params[:es_cell_names].nil?
      es_cell_names = params[:es_cell_names].split("\n").map{ |elm| elm.chomp.strip }.compact
      @es_cells = EsCell.all( :conditions => { :name => es_cell_names } )
      @es_cells.sort!{ |a,b| es_cell_names.index(a.name) <=> es_cell_names.index(b.name) }
    end

  end

  def update_multiple
    puts "update_multiple:"
    pp params[:distribution_qcs].values

    keys = params[:distribution_qcs].keys

    keys.each do |key|
      value = params[:distribution_qcs][key]
      next if value['karyotype_low'].to_s.size != 0
      next if value['karyotype_high'].to_s.size != 0
      next if value['copy_number'].to_s.size != 0
      next if value['five_prime_lr_pcr'].to_s.size != 0
      next if value['three_prime_lr_pcr'].to_s.size != 0
      next if value['five_prime_sr_pcr'].to_s.size != 0
      next if value['three_prime_sr_pcr'].to_s.size != 0
      next if value['thawing'].to_s.size != 0
      next if value['loa'].to_s.size != 0
      next if value['loxp'].to_s.size != 0
      next if value['lacz'].to_s.size != 0
      next if value['chr1'].to_s.size != 0
      next if value['chr8a'].to_s.size != 0
      next if value['chr8b'].to_s.size != 0
      next if value['chr11a'].to_s.size != 0
      next if value['chr11b'].to_s.size != 0
      next if value['chry'].to_s.size != 0
      params[:distribution_qcs].delete(key)
    end

    EsCell.transaction do
      @es_cells = EsCell.update( params[:es_cells].keys, params[:es_cells].values ).reject { |p| p.errors.empty? }
      @distribution_qcs = DistributionQc.update( params[:distribution_qcs].keys, params[:distribution_qcs].values ).reject { |p| p.errors.empty? }
    end

    es_cell_names = ''
    if ! @es_cells.empty? || ! @distribution_qcs.empty?
      hash = {}
      @es_cells.each do |es_cell|
        hash[es_cell.name] = 1
      end
      @distribution_qcs.each do |distribution_qc|
        hash[distribution_qc.es_cell.name] = 1
      end
      hash.keys.each {|key| es_cell_names += "#{key}\n" }
    end

    if @es_cells.empty? && @distribution_qcs.empty?
      flash[:notice] = "ES Cells Updated"
      redirect_to :action => :bulk_edit
    else
      flash[:error] = "There was a problem updating some of your records - the failed entries are shown below"
      redirect_to :action => :bulk_edit   , :es_cell_names => es_cell_names
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
