window.Digilys ?= {}

window.Digilys.loadMask = ($fields) ->
    $fields.css("position", "relative")
    $fields.append('<div class="load-mask"/>')


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

window.jQuery.fn.dataTableExt.oSort["sort-key-pre"] = (a) ->
    key = $(a).data("sort-key")

    if key == "-"
        return ""
    else
        return key

window.jQuery.fn.dataTableExt.oSort["sort-key-asc"] = window.jQuery.fn.dataTableExt.oSort["string-asc"]
window.jQuery.fn.dataTableExt.oSort["sort-key-desc"] = window.jQuery.fn.dataTableExt.oSort["string-desc"]

window.jQuery.fn.dataTableExt.ofnSearch["sort-key"] = (a) ->
    $a = $(a)
    cls = if !window.Digilys || !window.Digilys.currentResult then "value" else window.Digilys.currentResult

    $value = $a.find(".#{cls}")

    if $value.length > 0
        return $.trim($value.text())
    else
        return $a.data("sort-key")
