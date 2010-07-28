// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

document.observe('dom:loaded', function() {
  
  // Toggles to show/hide the ES Cell QC metrics
  $$('a.es_cell_qc_toggle').each( function(link) {
    link.observe( 'click', function(event) {
      event.stop();
      $(this).up('tr').next('tr.es_cell_qc').toggle();
    });
  });
  
});

