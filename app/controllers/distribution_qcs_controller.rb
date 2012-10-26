class DistributionQcsController < ApplicationController

  def create
    @distribution_qc = DistributionQc.new(params[:distribution_qc])

    respond_to do |format|
      if @distribution_qc.save
        format.json { render :json => @distribution_qc, :status => :created, :location => @distribution_qc }
        format.xml  { render :xml  => @distribution_qc, :status => :created, :location => @distribution_qc }
      else
        format.json { render :json => @distribution_qc.errors, :status => :unprocessable_entity }
        format.xml  { render :xml  => @distribution_qc.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @distribution_qc = DistributionQc.find( params[:id] )

    respond_to do |format|
      if @distribution_qc.update_attributes(params[:distribution_qc])
        format.json { render :json => { :id => @distribution_qc.id }, :location => @distribution_qc }
        format.xml  { render :xml  => { :id => @distribution_qc.id }, :location => @distribution_qc }
      else
        format.json { render :json => @distribution_qc.errors, :status => :unprocessable_entity }
        format.xml  { render :xml  => @distribution_qc.errors, :status => :unprocessable_entity }
      end
    end
  end

end
