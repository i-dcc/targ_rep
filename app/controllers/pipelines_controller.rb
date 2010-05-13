class PipelinesController < ApplicationController
  before_filter :find_pipeline, :only => [:show, :edit, :update, :destroy]
  
  # GET /pipelines
  # GET /pipelines.xml
  # GET /pipelines.json
  def index
    @pipelines = Pipeline.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml  => @pipelines }
      format.json { render :json => @pipelines }
    end
  end

  # GET /pipelines/1
  # GET /pipelines/1.xml
  # GET /pipelines/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml  => @pipeline }
      format.json { render :json => @pipeline }
    end
  end

  # GET /pipelines/new
  # GET /pipelines/new.xml
  def new
    @pipeline = Pipeline.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @pipeline }
    end
  end

  # GET /pipelines/1/edit
  def edit
  end

  # POST /pipelines
  # POST /pipelines.xml
  def create
    @pipeline = Pipeline.new(params[:pipeline])

    respond_to do |format|
      if @pipeline.save
        flash[:notice] = 'Pipeline was successfully created.'
        format.html { redirect_to(@pipeline) }
        format.xml  { render :xml => @pipeline, :status => :created, :location => @pipeline }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @pipeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pipelines/1
  # PUT /pipelines/1.xml
  # PUT /pipelines/1.json
  def update
    respond_to do |format|
      if @pipeline.update_attributes(params[:pipeline])
        flash[:notice] = 'Pipeline was successfully updated.'
        format.html { redirect_to(@pipeline) }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml  => @pipeline.errors, :status => :unprocessable_entity }
        format.json { render :json => @pipeline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pipelines/1
  # DELETE /pipelines/1.xml
  # DELETE /pipelines/1.json
  def destroy
    @pipeline.destroy

    respond_to do |format|
      format.html { redirect_to(pipelines_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
  
  private
  def find_pipeline
    @pipeline = Pipeline.find(params[:id])
  end
end
