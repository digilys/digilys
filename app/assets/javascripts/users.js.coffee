$ ->
    $(".user-autocomplete-field").each ->
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
                    { q: { email_cont: term }, page: page }
        )
