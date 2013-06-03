$ ->
    $("input.datepicker").datepicker(
        language:  "sv"
        format:    "yyyy-mm-dd"
        weekStart: 1
        autoclose: true
    )

    $("input.tag-field").each ->
        $field = $(this)

        tags = $field.data("existing-tags") ? []

        $field.select2(
            tags: tags
        )

        if $field.data("autofocus")
            $field.select2("open")

    $("form").on("change", ":input", ->
        window.onbeforeunload = ->
            return window.Digilys.navigationConfirmation
    ).on("submit", ->
        window.onbeforeunload = null
    )
