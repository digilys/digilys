$ ->
    window.Digilys.autocomplete(
        ".group-autocomplete-field",
        data: (term, page) ->
            terms = term.split(/\s*,\s*/)
            q = { name_cont: terms.shift() }

            for t, i in terms
                q["parent_#{i}_name_cont"] = t

            { q: q, page: page }
    )
