$ ->
    $("#student_group_ids").each ->
        $field = $(this)

        $field.select2(
            multiple: true,
            minimumInputLength: 3
            placeholder: $field.data("placeholder")
            ajax:
                url: $field.data("url")
                results: (data, page) ->
                    { results: data }
                data: (term, page) ->
                    terms = term.split(/\s*,\s*/)
                    q = { name_cont: terms.shift() }

                    for t, i in terms
                        q["parent_#{i}_name_cont"] = t

                    { q: q, page: page }
        )
