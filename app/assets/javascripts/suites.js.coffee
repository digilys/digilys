$ ->
    $(".suite-template-autocomplete-field").each ->
        $field = $(this)

        $field.select2(
            minimumInputLength: 3,
            placeholder: $field.data("placeholder")
            ajax:
                url: $field.data("url")
                results: (data, page) ->
                    { results: data }
                data: (term, page) ->
                    { q: { name_cont: term }, page: page }
        )

    $("#new_suite #suite_is_template").on "change", ->
        if ($(this).is(":checked"))
            $("#new_participant").hide()
        else
            $("#new_participant").show()
