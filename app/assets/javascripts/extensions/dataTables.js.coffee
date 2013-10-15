###
Sorting dataTables by a data-sort-key attribute
###

###
Preprocessing function, called before doing the actual sorting. This
returns the value of the data-sort-key attribute.

Filters sort keys with "-". The dash means there is no value, and
occurs due to the fact that we use the same method for the sort key
as printing the actual value to the user. If there's no value, the
user should see "-".
###
window.jQuery.fn.dataTableExt.oSort["sort-key-pre"] = (a) ->
    key = $(a).data("sort-key")

    if key == "-"
        return ""
    else
        return key

# The sorting of the data-sort-key values are done by comparing strings
window.jQuery.fn.dataTableExt.oSort["sort-key-asc"]  = window.jQuery.fn.dataTableExt.oSort["string-asc"]
window.jQuery.fn.dataTableExt.oSort["sort-key-desc"] = window.jQuery.fn.dataTableExt.oSort["string-desc"]

###
Handle sorting of columns of sort-key type.

This handles the color chart where it's possible to switch between
different values (value/stanine), and the search should respect whichever
is currently visible.

The current visible value is assumed to be stored in the variable
window.Digilys.currentResult.
###
window.jQuery.fn.dataTableExt.ofnSearch["sort-key"] = (a) ->
    $a = $(a)
    cls = if !window.Digilys || !window.Digilys.currentResult then "value" else window.Digilys.currentResult

    # The values are contained in elements with a class matching
    # the type of the value. If we can't find it, we search by
    # the sort key attribute
    $value = $a.find(".#{cls}")

    if $value.length > 0
        return $.trim($value.text())
    else
        return $a.data("sort-key")
