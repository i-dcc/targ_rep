class TargetingVectorsController < ApplicationController
  # GET /targeting_vectors
  # GET /targeting_vectors.xml
  def index
    @targeting_vectors = TargetingVector.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @targeting_vectors }
    end
  end

  # GET /targeting_vectors/1
  # GET /targeting_vectors/1.xml
  def show
    @targeting_vector = TargetingVector.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @targeting_vector }
    end
  end

  # GET /targeting_vectors/new
  # GET /targeting_vectors/new.xml
  def new
    @targeting_vector = TargetingVector.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @targeting_vector }
    end
  end

  # GET /targeting_vectors/1/edit
  def edit
    @targeting_vector = TargetingVector.find(params[:id])
  end

  # POST /targeting_vectors
  # POST /targeting_vectors.xml
  def create
    @targeting_vector = TargetingVector.new(params[:targeting_vector])

    respond_to do |format|
      if @targeting_vector.save
        flash[:notice] = 'TargetingVector was successfully created.'
        format.html { redirect_to(@targeting_vector) }
        format.xml  { render :xml => @targeting_vector, :status => :created, :location => @targeting_vector }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @targeting_vector.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /targeting_vectors/1
  # PUT /targeting_vectors/1.xml
  def update
    @targeting_vector = TargetingVector.find(params[:id])

    respond_to do |format|
      if @targeting_vector.update_attributes(params[:targeting_vector])
        flash[:notice] = 'TargetingVector was successfully updated.'
        format.html { redirect_to(@targeting_vector) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @targeting_vector.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /targeting_vectors/1
  # DELETE /targeting_vectors/1.xml
  def destroy
    @targeting_vector = TargetingVector.find(params[:id])
    @targeting_vector.destroy

    respond_to do |format|
      format.html { redirect_to(targeting_vectors_url) }
      format.xml  { head :ok }
    end
  end
end
