$ ->
    $(".student-autocomplete-field").each ->
        new Digilys.Autocomplete($(this), "first_name_or_last_name_cont")

    # Trigger the absent field for a generic result if the value is changed to
    # a blank value
    $("#student-form").each ->
        new Digilys.BlankTrigger
            form:          this
            inputs:        ".generic-results-inputs :input[id^=student_generic_results_attributes_][id$=_value]"
            triggerSuffix: "_value"
            booleanSuffix: "_absent"
