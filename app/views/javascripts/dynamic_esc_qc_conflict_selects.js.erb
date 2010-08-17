
var qc_options = new Array();
<% ESCELL_QC_OPTIONS.each do |qc_test,qc_conf| -%>
  <% if qc_test.match(/^user/) -%>
    <% qc_conf[:values].each do |qc_value| -%>
      qc_options.push( new Array("<%= qc_test %>", "<%= qc_value %>") );
    <% end -%>
  <% end -%>
<% end -%>

function update_esc_qc_conflict_options( test_select ) {
  qc_results_select = $(test_select).up('tr').down('select.esc_qc_conflicts_options');
  
  qc_test           = $(test_select).getValue();
  curr_qc_result    = $(qc_results_select).getValue();
  qc_results        = $(qc_results_select).options;
  qc_results.length = 1;
  
  qc_options.each( function(option) {
    if ( option[0] == qc_test ) {
      qc_results[qc_results.length] = new Option( option[1], option[1] );
    }
  });
  
  if ( qc_results.length == 1 ) {
    $(qc_results_select).disable();
  } else {
    $(qc_results_select).enable();
    $(qc_results_select).value = curr_qc_result;
  }
}

function setup_esc_conflict_selects() {
  $$('select.esc_qc_conflicts_test').each( function(test_select) {
    update_esc_qc_conflict_options(test_select);
    $(test_select).stopObserving;
    $(test_select).observe( 'change', function(event) { update_esc_qc_conflict_options(test_select) });
  });
}

document.observe( 'dom:loaded', function() {
  setup_esc_conflict_selects();
});