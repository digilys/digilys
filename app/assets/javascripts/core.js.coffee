window.Digilys ?= {}

window.Digilys.loadMask = ($fields) ->
    $fields.css("position", "relative")
    $fields.append('<div class="load-mask"/>')

$ ->
    $("[autofocus]:not(:focus)").eq(0).focus()

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

    $("form").on("change", ":input", (event) ->
        if !$(event.target).data("preventNavigationConfirmation")
            window.onbeforeunload = ->
                return window.Digilys.navigationConfirmation
    ).on("submit", ->
        window.onbeforeunload = null
    )
