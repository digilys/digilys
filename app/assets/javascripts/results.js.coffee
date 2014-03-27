$ ->
    $("#result-entry-form, #multiple-result-entry-form").each ->
        new Digilys.ResultValidator($(this))
        new Digilys.ResultDestroyer($(this))
