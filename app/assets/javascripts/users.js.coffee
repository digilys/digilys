$ ->
    $(".user-autocomplete-field").each ->
        new Digilys.Autocomplete($(this), "name_or_email_cont")
