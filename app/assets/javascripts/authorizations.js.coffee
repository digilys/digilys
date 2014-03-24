$ ->
    $(".authorization-autocomplete-field").each ->
        new Digilys.AuthorizationAutocomplete($(this), "name_or_email_cont")

    $(".authorization-table").each ->
        new Digilys.AuthorizationTable($(this))
