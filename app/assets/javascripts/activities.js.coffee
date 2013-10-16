$ ->
    $(".activity-students-autocomplete-field").each ->
        new window.Digilys.StudentGroupAutocomplete($(this))
