require 'test_helper'
require 'json'

class EsCellsControllerTest < ActionController::TestCase
  setup do
    user = Factory.create( :user )
    UserSession.create user
    Factory.create(:es_cell)
  end

  teardown do
    session = UserSession.find
    session.destroy
  end

  should "allow us to GET /index" do
    get :index
    assert_response :success
  end

  should "not allow us to GET /new" do
    assert_raise(ActionController::UnknownAction) { get :new }
  end

  should "not allow us to GET /edit without a cell id" do
    assert_raise(ActionController::UnknownAction) { get :edit }
  end

  should "allow us to create, update and delete an es_cell we made" do
    pipeline      = Factory.create( :pipeline )
    es_cell_attrs = Factory.attributes_for( :es_cell )

    # CREATE
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => EsCell.first.targeting_vector_id,
        :allele_id           => EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => pipeline.id
      }
    end
    assert_response :success, "Could not create ES Cell"

    created_es_cell = EsCell.search(:name => es_cell_attrs[:name]).last
    created_es_cell.created_by = @request.session["user_credentials_id"]
    created_es_cell.save!

    # UPDATE
    put :update, :id => created_es_cell.id, :es_cell => { :name => 'new name' }
    assert_response :success, "Could not update ES Cell"

    # DELETE
    assert_difference('EsCell.count', -1) do
      delete :destroy, :id => created_es_cell.id
    end
    assert_response :success, "Could not delete ES Cell"
  end

  should "allow us to create without providing a targeting vector" do
    pipeline      = Factory.create( :pipeline )
    es_cell_attrs = Factory.attributes_for( :es_cell )

    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name               => es_cell_attrs[:name],
        :parental_cell_line => es_cell_attrs[:parental_cell_line],
        :allele_id          => EsCell.first.allele_id,
        :mgi_allele_id      => es_cell_attrs[:mgi_allele_id],
        :pipeline_id        => pipeline.id
      }
    end
    assert_response :success
  end

  should "show an es_cell" do
    es_cell_id = EsCell.first.id

    get :show, :format => "html", :id => es_cell_id
    assert_response 406, "Controller should not allow HTML display"

    get :show, :format => "json", :id => es_cell_id
    assert_response :success, "Controller does not allow JSON display"

    get :show, :format => "xml", :id => es_cell_id
    assert_response :success, "Controller does not allow XML display"
  end

  should "not allow us to rename an existing cell to the same name as another cell" do
    pipeline        = Factory.create( :pipeline )
    es_cell_attrs   = Factory.attributes_for( :es_cell )
    another_escell  = Factory.create( :es_cell )

    # CREATE a valid ES Cell
    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => EsCell.first.targeting_vector_id,
        :allele_id           => EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => pipeline.id
      }
    end
    assert_response :success

    created_es_cell = EsCell.search(:name => es_cell_attrs[:name]).first

    # UPDATE - should fail as we're trying to enter a duplicate name
    put :update, :id => created_es_cell.id, :es_cell => { :name => another_escell.name }
    assert_response 400
  end

  should "not allow us to delete an es_cell when we're not the creator" do
    # Permission will be denied here because we are not deleting as the creator
    assert_no_difference('EsCell.count') do
      delete :destroy, :id => EsCell.first.id
    end
    assert_response 302
  end

  should "allow us to reparent an es_cell if we need to" do
    es_cell        = Factory.create( :es_cell, { :targeting_vector => nil } )
    current_parent = es_cell.allele
    new_parent     = Factory.create( :allele )

    assert_equal( es_cell.allele_id, current_parent.id, "WTF? The es_cell doesn't have the correct allele_id in the first place..." )

    put :update, :id => es_cell.id, :es_cell => { :allele_id => new_parent.id }
    assert_response :success

    es_cell = EsCell.find(es_cell.id)

    assert_not_equal( es_cell.allele_id, current_parent.id, "Ooops, we haven't switched parents..." )
    assert_equal( es_cell.allele_id, new_parent.id, "Ooops, we haven't switched parents..." )
  end

  should "allow us to interact with the /bulk_edit view" do
    get :bulk_edit
    assert_response :success, "Unable to open /es_cells/bulk_edit"

    post :bulk_edit, :es_cell_names => EsCell.first.name
    assert_response :success, "Unable to open /es_cells/bulk_edit with an es_cell_names parameter"
  end

  should "allow us to create/get using new distribution attributes" do
    pipeline      = Factory.create( :pipeline )
    es_cell_attrs = Factory.attributes_for( :es_cell )

    hash = {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => EsCell.first.targeting_vector_id,
        :allele_id           => EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => pipeline.id
    }

    distribution_attributes = [
      :distribution_qc_loa, :distribution_qc_loxp, :distribution_qc_lacz, :distribution_qc_chr1,
      :distribution_qc_chr8a, :distribution_qc_chr8b, :distribution_qc_chr11a,:distribution_qc_chr11b, :distribution_qc_chry
    ]

    settings = ['pass', 'fail', nil]

    distribution_attributes.each { |name| hash[name] = settings.sample }

    assert_difference('EsCell.count') do
      post :create, :es_cell => hash
    end
    assert_response :success, "Could not create ES Cell"

    created_es_cell = EsCell.search(:name => es_cell_attrs[:name]).last
    created_es_cell.created_by = @request.session["user_credentials_id"]
    created_es_cell.save!

    get :show, :id => created_es_cell.id, :es_cell => {:id => created_es_cell.id}
    assert_response :success, "Could not read ES Cell"

    created_es_cell = EsCell.find_by_name(es_cell_attrs[:name])

    hash.keys.each { |key| assert_equal hash[key], created_es_cell[key] }
  end

  should "prevent create using illegally set distribution attribute" do
    pipeline      = Factory.create( :pipeline )
    es_cell_attrs = Factory.attributes_for( :es_cell )
    hash = {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => EsCell.first.targeting_vector_id,
        :allele_id           => EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => pipeline.id,
        :distribution_qc_loa    => 'wibble'
    }
    post :create, :es_cell => hash
    assert_response 400, "Trying to create an illegal ES Cell"
  end

  should "show an es_cell (with new distribution_qc)" do

    es_cell = Factory.create(:es_cell)

    wtsi_distribution_qc = Factory.create(:distribution_qc, { :es_cell => es_cell, :centre => Centre.find_by_name!('WTSI') } )
    komp_centre = Factory.create(:distribution_qc, { :es_cell => es_cell, :centre => Centre.find_by_name!('KOMP') } )
    eucomm_centre = Factory.create(:distribution_qc, { :es_cell => es_cell, :centre => Centre.find_by_name!('EUCOMM') } )

    es_cell_id = es_cell.id

    get :show, :format => "html", :id => es_cell_id
    assert_response 406, "Controller should not allow HTML display"

    response = get :show, :format => "json", :id => es_cell_id
    assert_response :success, "Controller does not allow JSON display"

    object = JSON.load response.body

    found = false

    object['distribution_qcs'].each do |distribution_qc|
      distribution_qc.keys.each do |key|
        next if %W(centre_name centre_id id).include? key
        assert_equal wtsi_distribution_qc[key.underscore.to_sym], distribution_qc[key], "Expected #{wtsi_distribution_qc[key.underscore.to_sym]} got #{distribution_qc[key]} for #{key}"
        found = true
      end
    end

    assert found, "Did not find expected values (1)!"

    get :show, :format => "xml", :id => es_cell_id
    assert_response :success, "Controller does not allow XML display"
  end

  should "update an es_cell (with new distribution_qc)" do
    #es_cell = Factory.create(:es_cell)
    #wtsi_distribution_qc = Factory.create(:distribution_qc, { :es_cell => es_cell, :centre => Factory.create( :centre ) } )
    #id = es_cell.distribution_qcs.first.id

    wtsi_distribution_qc = Factory.create(:distribution_qc, { :centre => Factory.create( :centre ) } )
    es_cell = wtsi_distribution_qc.es_cell
    id = es_cell.distribution_qcs.first.id

    target = {
      :id => id,
      :five_prime_sr_pcr => ['pass', 'fail'].sample,
      :three_prime_sr_pcr => ['pass', 'fail'].sample,
      :copy_number => ['pass', 'fail'].sample,
      :five_prime_lr_pcr => ['pass', 'fail'].sample,
      :three_prime_lr_pcr => ['pass', 'fail'].sample,
      :thawing => ['pass', 'fail'].sample,
      :loa => ['pass', 'fail', 'passb'].sample,
      :loxp => ['pass', 'fail'].sample,
      :lacz => ['pass', 'fail'].sample,
      :chr1 => ['pass', 'fail'].sample,
      :chr8a => ['pass', 'fail'].sample,
      :chr8b => ['pass', 'fail'].sample,
      :chr11a => ['pass', 'fail'].sample,
      :chr11b => ['pass', 'fail'].sample,
      :chry => ['pass', 'fail', 'passb'].sample,
      :karyotype_low => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
      :karyotype_high => [0.1, 0.2, 0.3, 0.4, 0.5].sample
    }

    put :update, :id => es_cell.id, :es_cell => { :distribution_qcs_attributes => [ target ] }
    assert_response :success

    response = get :show, :format => "json", :id => es_cell.id
    assert_response :success, "Controller does not allow JSON display"

    object = JSON.load response.body

    found = false
    object['distribution_qcs'].each do |distribution_qc|
      if distribution_qc['id'] == id
        target.keys.each do |key|
            key2 = key.to_s.gsub(/\:/, '')
            assert_equal target[key], distribution_qc[key2], "Expected '#{target[key]}' - found '#{distribution_qc[key2]}' for key #{key}"
        end
        found = true
        break
      end
    end

    assert found, "Did not find expected values (2)!"

    dqc = DistributionQc.find id

    target.keys.each do |key|
      assert_equal target[key], dqc[key], "Expected '#{target[key]}' - found '#{dqc[key]}' for key #{key}"
    end
  end

  should "create an es_cell (with new distribution_qc) using only centre name" do
    pipeline      = Factory.create( :pipeline )
    es_cell_attrs = Factory.attributes_for( :es_cell )

    assert_difference('EsCell.count') do
      post :create, :es_cell => {
        :name                => es_cell_attrs[:name],
        :parental_cell_line  => es_cell_attrs[:parental_cell_line],
        :targeting_vector_id => EsCell.first.targeting_vector_id,
        :allele_id           => EsCell.first.allele_id,
        :mgi_allele_id       => es_cell_attrs[:mgi_allele_id],
        :pipeline_id         => pipeline.id
      }
    end

    es_cell = EsCell.last

    assert_equal es_cell.name, es_cell_attrs[:name]
    assert_equal es_cell.parental_cell_line, es_cell_attrs[:parental_cell_line]
    assert_equal es_cell.targeting_vector_id, EsCell.first.targeting_vector_id
    assert_equal es_cell.allele_id, EsCell.first.allele_id
    assert_equal es_cell.mgi_allele_id, es_cell_attrs[:mgi_allele_id]
    assert_equal es_cell.pipeline_id, pipeline.id
    assert_equal 0, es_cell.distribution_qcs.size

    response = get :show, :format => "json", :id => es_cell.id
    assert_response :success, "Controller does not allow JSON display"

    target = {
      :centre_name => 'WTSI',
      :five_prime_sr_pcr => ['pass', 'fail'].sample,
      :three_prime_sr_pcr => ['pass', 'fail'].sample,
      :copy_number => ['pass', 'fail'].sample,
      :five_prime_lr_pcr => ['pass', 'fail'].sample,
      :three_prime_lr_pcr => ['pass', 'fail'].sample,
      :thawing => ['pass', 'fail'].sample,
      :loa => ['pass', 'fail', 'passb'].sample,
      :loxp => ['pass', 'fail'].sample,
      :lacz => ['pass', 'fail'].sample,
      :chr1 => ['pass', 'fail'].sample,
      :chr8a => ['pass', 'fail'].sample,
      :chr8b => ['pass', 'fail'].sample,
      :chr11a => ['pass', 'fail'].sample,
      :chr11b => ['pass', 'fail'].sample,
      :chry => ['pass', 'fail', 'passb'].sample,
      :karyotype_low => [0.1, 0.2, 0.3, 0.4, 0.5].sample,
      :karyotype_high => [0.1, 0.2, 0.3, 0.4, 0.5].sample
    }

    put :update, :id => es_cell.id, :es_cell => { :distribution_qcs_attributes => [target] }
    assert_response :success

    es_cell.reload

    id = es_cell.distribution_qcs.first.id

    dqc = DistributionQc.find id

    target[:id] = id

    assert_equal 'WTSI', dqc.centre_name

    target.delete(:centre_name)

    target.keys.each do |key|
      assert_equal target[key], dqc[key], "Expected '#{target[key]}' - found '#{dqc[key]}' for key #{key}"
    end

  end

end
