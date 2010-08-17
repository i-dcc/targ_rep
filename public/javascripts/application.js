// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Toggles to show/hide the ES Cell QC metrics
function setup_qc_metric_toggles() {
  $$('a.es_cell_qc_toggle').each( function(link) {
    link.stopObserving('click');
    link.observe( 'click', function(event) {
      event.stop();
      $(this).up('tr').next('tr.es_cell_qc').toggle();
    });
  });
}

document.observe('dom:loaded', function() {
  setup_qc_metric_toggles();
});

