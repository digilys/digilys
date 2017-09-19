// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require error_handling
//= require jquery_ujs
//= require jquery-ui/widgets/sortable
//= require rails_sortable
//= require bootstrap
//= require select2
//= require bootstrap-datepicker/core
//= require bootstrap-datepicker/locales/bootstrap-datepicker.sv
//= require jasny-bootstrap
//= require slickgrid/jquery.event.drag-2.2.js
//= require slickgrid/jquery-ui-1.10.4.custom.js
//= require slickgrid/slick.core.js
//= require slickgrid/slick.dataview.js
//= require slickgrid/slick.grid.js
//= require slickgrid/slick.headermenu.js
//= require_tree ./vendor
//= require_tree ./defaults
//= require core
//= require_tree .

$(".sortable").railsSortable({
  // Table headers are not to be dragged and sorted
  cancel: "th"
});

/** Enable/Disable template button when creating new evaluation. **/
function noTemplateChosen() {
  selections = document.getElementsByClassName("select2-search-choice");
  disabled = !(selections != null && 0 < selections.length);
  button = document.getElementById("use_template_action");
  button.disabled = disabled;
}

/** Check non-virtual current instance in check-box list of instances. **/
function checkCurrentInstance(instance_id) {
  if (instance_id.length != 0) {
    check_boxes = document.getElementsByClassName("choice checkbox");
    for (i = 0; i < check_boxes.length; ++i) {
      if (check_boxes[i].children[0].value == instance_id) {
        check_boxes[i].children[0].checked = true;
      }
    }
  }
}
