class AllelesController < ApplicationController
  before_filter :require_user, :only => [:index, :show, :new, :edit, :create, :update, :destroy]
  before_filter :find_allele,
    :only => [
      :update, :destroy,
      :escell_clone_genbank_file,
      :targeting_vector_genbank_file,
      :escell_clone_cre_genbank_file,
      :targeting_vector_cre_genbank_file,
      :escell_clone_flp_genbank_file,
      :targeting_vector_flp_genbank_file,
      :escell_clone_flp_cre_genbank_file,
      :targeting_vector_flp_cre_genbank_file,
      :allele_image,
      :cassette_image,
      :vector_image,
      :allele_image_cre,
      :allele_image_flp,
      :allele_image_flp_cre,
      :vector_image_cre,
      :vector_image_flp,
      :vector_image_flp_cre,
      :history
    ]
  before_filter :check_for_genbank_file,
    :only => [
      :escell_clone_genbank_file,
      :targeting_vector_genbank_file,
      :escell_clone_cre_genbank_file,
      :targeting_vector_cre_genbank_file,
      :escell_clone_flp_genbank_file,
      :targeting_vector_flp_genbank_file,
      :escell_clone_flp_cre_genbank_file,
      :targeting_vector_flp_cre_genbank_file,
      :allele_image,
      :vector_image,
      :allele_image_cre,
      :allele_image_flp,
      :allele_image_flp_cre,
      :vector_image_cre,
      :vector_image_flp,
      :vector_image_flp_cre,
    ]
  before_filter :check_for_escell_genbank_file, :only => [ :escell_clone_genbank_file, :escell_clone_cre_genbank_file, :escell_clone_flp_genbank_file, :escell_clone_flp_cre_genbank_file, :allele_image, :allele_image_cre, :allele_image_flp, :allele_image_flp_cre ]
  before_filter :check_for_vector_genbank_file, :only => [ :targeting_vector_genbank_file, :targeting_vector_cre_genbank_file, :targeting_vector_flp_genbank_file, :targeting_vector_flp_cre_genbank_file, :vector_image, :vector_image_cre, :vector_image_flp, :vector_image_flp_cre ]
  # Must be after "find_allele" filter (as it requires an object)
  before_filter :ensure_creator_or_admin, :only => [:destroy]

  # The following are located in application_controller.rb
  before_filter :get_qc_field_descriptions, :only => [:show, :new, :create, :edit, :update, :destroy]

  # For webservice interface
  before_filter :format_nested_params, :only => [:create, :update]

  # GET /alleles
  # GET /alleles.xml
  # GET /alleles.json
  def index
    params[:page] ||= 1
    allele_params = setup_allele_search(params)
    @alleles = Allele.search( allele_params ).paginate(
      :page    => params[:page],
      :select  => "distinct alleles.*",
      :include => [ { :targeting_vectors => :pipeline }, { :es_cells => :pipeline } ]
    )
    mutational_drop_downs

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml   => @alleles }
      format.json { render :json  => @alleles }
    end
  end

  # GET /alleles/1
  # GET /alleles/1.xml
  # GET /alleles/1.json
  def show
    @allele = Allele.find(
      params[:id],
      :include => [
        :genbank_file,
        { :targeting_vectors => :pipeline },
        { :es_cells => [ :pipeline, :es_cell_qc_conflicts ] }
      ]
    )
    @es_cells = @allele.es_cells.sort{ |a,b| a.name <=> b.name }
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml   => @allele }
      format.json { render :json  => @allele }
    end
  end

  # GET /alleles/new
  def new
    @allele = Allele.new
    mutational_drop_downs
    @allele.genbank_file = GenbankFile.new
    @allele.targeting_vectors.build
    @allele.es_cells.build
  end

  # GET /alleles/1/edit
  def edit
    @allele = Allele.find(
      params[:id],
      :include => [
        :genbank_file,
        { :targeting_vectors => :pipeline },
        { :es_cells => [ :pipeline, :es_cell_qc_conflicts ] }
      ]
    )
    mutational_drop_downs
    @allele.genbank_file = GenbankFile.new if @allele.genbank_file.nil?

    @allele.es_cells.each do |es_cell|
      es_cell.build_distribution_qc(current_user.centre)
    end

    @allele.es_cells.sort!{ |a,b| a.name <=> b.name }
  end

  # POST /alleles
  # POST /alleles.xml
  # POST /alleles.json
  def create
    @allele = Allele.new( params[:allele] )
    mutational_drop_downs

    respond_to do |format|
      if @allele.save
        # Useful for all formats, not only HTML
        update_links_escell_to_targ_vec( @allele.id, params[:allele] )

        format.html {
          flash[:notice] = 'Allele successfully created.'
          redirect_to @allele
        }
        format.xml  { render :xml  => @allele, :status => :created, :location => @allele }
        format.json { render :json => @allele, :status => :created, :location => @allele }
      else
        format.html {
          @allele.genbank_file = GenbankFile.new
          render :action => "new"
        }
        format.xml  { render :xml  => @allele.errors, :status => :unprocessable_entity }
        format.json { render :json => @allele.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /alleles/1
  # PUT /alleles/1.xml
  def update
    mutational_drop_downs
    respond_to do |format|
      if @allele.update_attributes(params[:allele])
        # Useful for all formats, not only HTML
        update_links_escell_to_targ_vec( @allele.id, params[:allele] )

        format.html {
          flash[:notice] = 'Allele successfully updated.'
          redirect_to @allele
        }
        format.xml  { render :xml  => @allele }
        format.json { render :json => @allele }
      else
        format.html {
          if @allele.genbank_file.nil?
            @allele.genbank_file = GenbankFile.new
          end
          render :action => "edit"
        }
        format.xml  { render :xml   => @allele.errors, :status => :unprocessable_entity }
        format.json { render :json  => @allele.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /alleles/1
  # DELETE /alleles/1.xml
  def destroy
    @allele.destroy
    mutational_drop_downs

    respond_to do |format|
      format.html { redirect_to :back }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

  ##
  ## Custom controllers
  ##

  # GET /alleles/1/escell_clone_genbank_file/
  def escell_clone_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone)
  end

  # GET /alleles/1/targeting-vector-genbank-file/
  def targeting_vector_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector)
  end

  def escell_clone_cre_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone_cre)
  end

  def targeting_vector_cre_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector_cre)
  end

  def escell_clone_flp_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone_flp)
  end

  def targeting_vector_flp_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector_flp)
  end

  def escell_clone_flp_cre_genbank_file
    send_genbank_file(@allele.genbank_file.escell_clone_flp_cre)
  end

  def targeting_vector_flp_cre_genbank_file
    send_genbank_file(@allele.genbank_file.targeting_vector_flp_cre)
  end

  def send_genbank_file(genbank_string)
    send_data(
      "<pre>#{genbank_string}</pre>",
      {
        :type        => 'text/html',
        :disposition => 'inline'
      }
    )
  end

  # GET /alleles/1/allele-image/
  def allele_image
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.escell_clone).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/allele-image-cre/
  def allele_image_cre
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.escell_clone_cre).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/allele-image-flp/
  def allele_image_flp
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.escell_clone_flp).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/allele-image-flp-cre/
  def allele_image_flp_cre
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.escell_clone_flp_cre).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/cassette-image/
  def cassette_image
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.escell_clone, true).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image/
  def vector_image
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.targeting_vector ).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image-cre/
  def vector_image_cre
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.targeting_vector_cre ).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image-flp/
  def vector_image_flp
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.targeting_vector_flp ).render.to_blob { self.format = "PNG" })
  end

  # GET /alleles/1/vector-image-flp-cre/
  def vector_image_flp_cre
    send_allele_image(AlleleImage::Image.new( @allele.genbank_file.targeting_vector_flp_cre ).render.to_blob { self.format = "PNG" })
  end

  def send_allele_image(allele_image)
    send_data(
      allele_image,
      {
        :disposition => "inline",
        :type => "image/png"
      }
    )
  end

:allele_image_cre
:allele_image_flp
:allele_image_flp_cre
:vector_image_cre
:vector_image_flp
:vector_image_flp_cre

  # GET /alleles/1/history/
  def history
  end

  private
    def find_allele
      @allele = Allele.find(params[:id])
    end

    def mutational_drop_downs
      @mutation_type = MutationType.all
      @mutation_subtype = MutationSubtype.all
      @mutation_method = MutationMethod.all
    end

    def setup_allele_search(params)
      allele_params = params.dup

      # Just keep Molecular Structure params.
      allele_params.delete( "controller" )
      allele_params.delete( "action" )
      allele_params.delete( "format" )
      allele_params.delete( "page" )

      if allele_params.include? :search
        allele_params = params[:search]
      elsif allele_params[ :loxp_start ] == 'null' and allele_params[ :loxp_end ] == 'null'
        # 'loxp_start_null' and 'loxp_end_null' should be used to force
        # these fields to be null
        allele_params.delete( :loxp_start )
        allele_params.delete( :loxp_end )
        allele_params.update({ :loxp_start_null => true, :loxp_end_null => true })
      end

      # Search on marker_symbol against SolR and returns
      if allele_params.include? :marker_symbol and !allele_params[:marker_symbol].blank?
        marker_symbol = allele_params.delete( :marker_symbol )
        solr_results = search_solr({
          :q   => "marker_symbol:#{marker_symbol}",
          :fl  => "mgi_accession_id"
        })
        docs = solr_results['response']['docs']

        unless docs.empty?
          allele_params.update({ :mgi_accession_id => docs[0]['mgi_accession_id'] })
        end
      end

      return allele_params
    end

    def format_nested_params
      # Specific to create/update methods - webservice interface
      params[:allele] = params.delete(:molecular_structure) if params[:molecular_structure]
      allele_params = params[:allele]

      # README: http://htgt.internal.sanger.ac.uk:4005/issues/257
      #
      # 'accepts_nested_attributes_for' (in model.rb) expects
      # <child_model>_attributes as a key in params hash in order to
      # create <child_model> objects.
      # For now, it is allowed to send a nested Array such as 'es_cells'
      # instead of the expected 'es_cell_attributes' Array.
      # This function will rename/move 'es_cells' to 'es_cell_attributes'.
      #
      # Because of the rails issue (see ticket):
      # This function will also add the 'nested => true' key/value pair to each
      # hash contained in the Array so that the model does not try to validate
      # the ES Cell before the molecular structure gets its ID (creation only).

      ##
      ##  ES Cells
      ##

      if allele_params.include? :es_cells
        allele_params[:es_cells].each { |attrs| attrs[:nested] = true }
        allele_params[:es_cells_attributes] = allele_params.delete(:es_cells)
      elsif not allele_params.include? :es_cells_attributes
        allele_params[:es_cells_attributes] = []
      end

      ##
      ##  Targeting Vectors + their ES Cells
      ##

      if allele_params.include? :targeting_vectors
        allele_params[:targeting_vectors].each do |attrs|
          attrs.update({ :nested => true })

          # Move 'es_cells' Array related to this Targeting Vector
          # into the 'es_cells_attributes' Array created above.
          # es_cell hash will contain targeting_vector_name so that it can be
          # related to the proper targeting_vector when it gets an ID.
          if attrs.include? :es_cells
            attrs[:es_cells].each do |es_cell_attr|
              es_cell_attr.update({ :nested => true, :targeting_vector_name => attrs[:name] })
              allele_params[:es_cells_attributes].push( es_cell_attr )
            end
            attrs.delete( :es_cells )
          end
        end

        allele_params[:targeting_vectors_attributes] = allele_params.delete(:targeting_vectors)
      end

      ##
      ##  Genbank Files
      ##

      if allele_params.include? :genbank_file
        allele_params[:genbank_file].update({ :nested => true })
        allele_params[:genbank_file_attributes] = allele_params.delete(:genbank_file)
      end

      # Don't create genbank file object if its attributes are empty.
      gb_files_attrs = allele_params[:genbank_file_attributes]
      if gb_files_attrs
        gb_escell   = gb_files_attrs[:escell_clone]
        gb_targ_vec = gb_files_attrs[:targeting_vector]

        if ( gb_escell.nil? and gb_targ_vec.nil? ) or ( gb_escell.empty? and gb_targ_vec.empty? )
          allele_params.delete(:genbank_file_attributes)
        end
      end
    end

    def four_oh_four
      respond_to do |format|
        format.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => "404 Not Found" }
        format.all { render :nothing => true, :status => "404 Not Found" }
      end
    end

    def check_for_genbank_file
      four_oh_four() if @allele.genbank_file.nil?
    end

    def check_for_escell_genbank_file
      four_oh_four() if @allele.genbank_file.escell_clone.nil? || @allele.genbank_file.escell_clone.empty?
    end

    def check_for_vector_genbank_file
      four_oh_four() if @allele.genbank_file.targeting_vector.nil? || @allele.genbank_file.targeting_vector.empty?
    end

    # One can give a targeting_vector_name instead of a targeting_vector_id
    # to link an ES Cell to its Targeting Vector.
    # This function will find the right targeting vector from the given name
    def update_links_escell_to_targ_vec( allele_id, params )
      return unless params.include? :es_cells_attributes

      es_cells_attrs = []
      if params[:es_cells_attributes].is_a? Array
        params[:es_cells_attributes].each do |attrs|
          es_cells_attrs.push( attrs )
        end
      else
        params[:es_cells_attributes].each do |key, attrs|
          es_cells_attrs.push( attrs )
        end
      end

      es_cells_attrs.each do |attrs|
        next if attrs.include? :_destroy and attrs[:_destroy] == "1"

        if attrs.include? :targeting_vector_name

          # Find ES Cell from its 'id' or its 'name' + 'allele_id'
          if attrs.include? :id
            es_cell = EsCell.find( attrs[:id] )
          else
            search  = EsCell.search({ :name_like => attrs[:name], :allele_id_is => allele_id })
            es_cell = search.first
          end

          # Find targeting vector from given name and link it to the ES Cell
          if es_cell and es_cell.targeting_vector.nil?
            search = TargetingVector.name_is(attrs[:targeting_vector_name])
            es_cell.targeting_vector = search.first
            es_cell.save
          end
        end
      end
    end
end
