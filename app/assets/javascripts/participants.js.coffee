$ ->
    $("#participant_student_id").each ->
        $field = $(this)

        $field.select2(
            minimumInputLength: 3
            placeholder: $field.data("placeholder")
            ajax:
                url: $field.data("url")
                results: (data, page) ->
                    { results: data }
                data: (term, page) ->
                    { q: { name_cont: term }, page: page }
        )
