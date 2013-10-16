window.Digilys ?= {}

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
        new Digilys.TagField($(this))

    $("form:not(.prevent-navigation-confirmation)").on("change", ":input", (event) ->
        if !$(event.target).data("preventNavigationConfirmation")
            window.onbeforeunload = ->
                return window.Digilys.navigationConfirmation
    ).on("submit", ->
        window.onbeforeunload = null
    )
