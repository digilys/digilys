$ ->
    window.Digilys.autocomplete(
        ".student-autocomplete-field",
        data: (term, page) ->
            { q: { first_name_or_last_name_cont: term }, page: page }
    )

    # Trigger the destroy field for a generic result if the value is changed to
    # a blank value
    $("#student-form").on "change", ".generic-results-inputs :input", ->
        if this.id.match(/student_generic_results_attributes_\d+_value/)
            destroyId     = this.id.replace("_value", "__destroy")
            $destroyInput = $("#" + destroyId)

            if $destroyInput.length == 1
                value = $.trim($(this).val())

                if value.length > 0
                    $destroyInput.val("0")
                else
                    $destroyInput.val("1")
