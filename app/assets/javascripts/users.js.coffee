$ ->
    window.Digilys.autocomplete(
        ".user-autocomplete-field",
        data: (term, page) ->
            { q: { name_or_email_cont: term }, page: page }
    )
