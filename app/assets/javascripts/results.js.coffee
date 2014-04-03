$ ->
    $("#result-entry-form, #multiple-result-entry-form").each ->
        new Digilys.ResultEntryForm($(this))
