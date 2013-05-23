$ ->
    $("input.datepicker").datepicker(
        language:  "sv"
        format:    "yyyy-mm-dd"
        weekStart: 1
    )

    $("input.tag-field").select2(
        tags: []
    )
