module AllelesHelper
  # Following helpers come from: 
  # http://railsforum.com/viewtopic.php?id=28447
  
  # Add a new es cell form
  def add_es_cell_link(form_builder)
    link_to_function( 'Add an ES Cell', { :class => 'ss_sprite ss_add' } ) do |page|
      form_builder.fields_for :es_cells, EsCell.new, :child_index => 'NEW_RECORD' do |f|
        html = render( :partial => 'es_cell_form', :locals => { :f => f } )
        page << "$('es_cells').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()) });"
        page << "setup_qc_metric_toggles();"
      end
    end
  end
  
  # Display the remove link for an es cell form
  def remove_es_cell_link(form_builder)
    if form_builder.object.new_record?
      # If the es cell is a new record, we can just remove from the dom
      link_to_function( "remove", { :class => 'ss_sprite ss_cross' } ) do |page|
        page << "$(this).up('tr.es_cell').next('tr.es_cell_qc').remove();"
        page << "$(this).up('tr.es_cell').remove();"
      end
    else
      # However if it's a "real" record it has to be deleted from the database,
      # for this reason the new fields_for, accept_nested_attributes helpers give us _destroy,
      # a virtual attribute that tells rails to delete the child record.
      form_elm = form_builder.hidden_field(:_destroy)
      link_elm = link_to_function("remove", { :class => 'ss_sprite ss_cross' } ) do |page|
        page << "$(this).up('tr.es_cell').next('tr.es_cell_qc').hide();"
        page << "$(this).up('tr.es_cell').hide();"
        page << "$(this).previous().value = '1';"
      end
      
      return form_elm + link_elm
    end
  end
  
  # Add a new targeting vector form
  def add_targ_vec_link(form_builder)
    link_to_function( 'Add a targeting vector', { :class => 'ss_sprite ss_add' } ) do |page|
      form_builder.fields_for :targeting_vectors, TargetingVector.new, :child_index => 'NEW_RECORD' do |f|
        html = render :partial => 'targ_vec_form', :locals => { :f => f } 
        page << "$('targeting_vectors').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()) });"
      end
    end
  end
  
  # Display the remove link for a targeting vector form
  def remove_targ_vec_link(form_builder)
    if form_builder.object.new_record?
      # If the targeting vector is a new record, we can just remove the div from the dom
      link_to_function( "remove", { :class => 'ss_sprite ss_cross' } ) do |page|
        page << "$(this).up('.targeting_vector').remove();"
      end
    else
      # However if it's a "real" record it has to be deleted from the database,
      # for this reason the new fields_for, accept_nested_attributes helpers give us _destroy,
      # a virtual attribute that tells rails to delete the child record.
      form_builder.hidden_field(:_destroy) +
      link_to_function( "remove", { :class => 'ss_sprite ss_cross' } ) do |page|
        page << "$(this).up('.targeting_vector').hide(); $(this).previous().value = '1';"
      end
    end
  end
  
  # Add a new es cell qc conflict form
  def add_es_cell_qc_conflict_link(form_builder)
    link_to_function( 'Add A QC Conflict Report', { :class => 'ss_sprite ss_add' } ) do |page|
      form_builder.fields_for :es_cell_qc_conflicts, EsCellQcConflict.new, :child_index => 'NEW_RECORD' do |f|
        html = render( :partial => 'alleles/es_cell_qc_conflict_form', :locals => { :f => f } )
        page << "$(this).up('td').down('table.esc_qc_conflicts tbody').insert({ bottom: '#{escape_javascript(html)}'.replace(/NEW_RECORD/g, new Date().getTime()) });"
        page << "setup_esc_conflict_selects();"
      end
    end
  end
  
  # Display the remove link for an es cell qc conflict form
  def remove_es_cell_qc_conflict_link(form_builder)
    if form_builder.object.new_record?
      # If the es cell is a new record, we can just remove from the dom
      link_to_function( "remove", { :class => 'ss_sprite ss_cross' } ) do |page|
        page << "$(this).up('tr').remove();"
      end
    else
      # However if it's a "real" record it has to be deleted from the database,
      # for this reason the new fields_for, accept_nested_attributes helpers give us _destroy,
      # a virtual attribute that tells rails to delete the child record.
      form_elm = form_builder.hidden_field(:_destroy)
      link_elm = link_to_function("remove", { :class => 'ss_sprite ss_cross' } ) do |page|
        page << "$(this).up('tr').hide();"
        page << "$(this).previous().value = '1';"
      end
      
      return form_elm + link_elm
    end
  end
end
