window.Digilys ?= {}

# Common method for initializing a select2-based autocomplete
window.Digilys.autocomplete = (selectorOrElem, options = {}) ->

    options.results ?= (data, page) ->
        { results: data.results, more: data.more }

    $(selectorOrElem).each ->
        $field = $(this)

        opts =
            width:              "off"
            multiple:           $field.data("multiple")
            minimumInputLength: 0
            placeholder:        $field.data("placeholder")
            ajax:
                url:            $field.data("url")
                results:        options.results
                data:           options.data

        opts.formatResult = options.formatResult if options.formatResult

        $field.select2(opts)

        data = $field.data("data")

        if data
            $field.select2("data", data)

        if $field.data("autofocus")
            $field.select2("open")

# Callback for saving data table state, with throttling functionality
window.Digilys.dataTable ?= {}
window.Digilys.dataTable.stateTimeoutId = null
window.Digilys.dataTable.saveState = (state, url) ->

    if window.Digilys.dataTable.stateTimeoutId
        window.clearTimeout(window.Digilys.dataTable.stateTimeoutId)

    callback = ->
        $.post(url, { _method: "PUT", state: JSON.stringify(state) })

    window.Digilys.dataTable.stateTimeoutId = window.setTimeout(callback, 1000)

$ ->
    $("[autofocus]:not(:focus)").eq(0).focus()
    $(":input[placeholder]").placeholder()

    $("#eula-modal").modal("show")

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

    $("form:not(.prevent-navigation-confirmation)").on("change", ":input", (event) ->
        if !$(event.target).data("preventNavigationConfirmation")
            window.onbeforeunload = ->
                return window.Digilys.navigationConfirmation
    ).on("submit", ->
        window.onbeforeunload = null
    )
