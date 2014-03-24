$ ->
    $(".evaluation-autocomplete-field").each ->
        new Digilys.EvaluationAutocomplete($(this))

    colorTable = $("#color-table")

    if colorTable.length > 0
        ct = new Digilys.ColorTable(
            colorTable,
            Digilys.colorTable.columns,
            Digilys.colorTable.data,
            Digilys.colorTable.columnMenu
        )

        # State handling
        saveStateUrl = colorTable.data("save-local-state-url")

        colorTable.on "state-change", () ->
            utils.throttle 1000, "color-table-state-saving", ->
                $.post(saveStateUrl, { _method: "PUT", state: JSON.stringify(ct.getState()) })

        if Digilys.colorTable.state
            ct.setState(Digilys.colorTable.state)

        # Toggle between different values in the result table
        $(".result-toggles").on "click", ".btn:not(.active)", ->
            button = $(this)

            # Switch to the clicked button
            button.addClass "active"
            button.siblings().removeClass "active"

            # Change which value is displayed by replacing the CSS class
            colorTable.attr "class", (i, cls) ->
                cls.replace /show-\w+/, "show-#{button.data("value")}"

        $(".slick-header-column[title]", colorTable).tooltip(
            html:      true
            placement: "top"
            delay:     { show: 300, hide: 100 }
            container: "body"
        )

        $("#color-table-group-selector").select2().on "change", -> ct.groupFilter($(this).val())

        # Student popover
        studentUrlTemplate = colorTable.data("student-url-template")

        new Digilys.SinglePopover colorTable, content: ->
            content = $("<div/>")
            content.load(studentUrlTemplate.replace(":id", $(this).data("id")))
            return content

        colorTable.on "shown", (event) ->
            $(".popover").addClass("ajax-popover") if $(event.target).is(".student-action")

        # Close popovers when clicking outside a popover
        Digilys.bindPopoverCloser($("body"))

