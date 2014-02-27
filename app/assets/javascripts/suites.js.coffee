$ ->
    $(".suite-template-autocomplete-field").each ->
        autocomplete = new Digilys.Autocomplete($(this))
        autocomplete.enableAutosubmit("form")

    $("#new_suite #suite_is_template").on "change", ->
        if ($(this).is(":checked"))
            $("#new_participant").hide()
        else
            $("#new_participant").show()

    $(".suite-users-table").each -> new Digilys.RemoteToggleList(this, "user_ids")

    $(".evaluation-status-progress[title]").tooltip(
        html:      true
        placement: "right"
        delay:     { show: 300, hide: 100 }
    )

    colorTable = $(".color-table")

    if colorTable.length > 0
        # Don't fire the click event on the th element, it causes
        # a column sort
        $(".column-menu-action", colorTable).on "click", (event) ->
            # Just trigger the event on the row, bypassing everything inside
            # the header
            $(this).closest("tr").trigger(event)
            return false

        # Evaluation info popup
        $("th[title]", colorTable).tooltip(
            html:      true
            placement: "top"
            delay:     { show: 300, hide: 100 }
            container: "body"
        )

        tableState   = colorTable.data("table-state")

        dataTable = $(".data-table", colorTable).dataTable(
            bSortCellsTop:   true
            bPaginate:       false
            bInfo:           false
            bStateSave:      true
            sScrollX:        "100%"
            sScrollY:        ""
            bScrollCollapse: true
            aoColumnDefs:  [
                {
                    aTargets: [ "_all" ],
                    sType:    "sort-key"
                }
            ]
            fnStateLoad: (settings) ->
                domIds = $.makeArray(this.find("thead tr:first th").map -> this.id)
                return Digilys.datatables.processStateForLoading(tableState, domIds)
            fnStateSave: (settings, state) ->
                settings = this.fnSettings()
                fixedColumns = if settings._oFixedColumns then settings._oFixedColumns.s.iLeftColumns

                state = Digilys.datatables.processStateForSaving(
                    state,
                    settings.aoColumns
                    fixedColumns: fixedColumns
                )

                url = colorTable.data("save-local-state-path")
                this.data("current-state", state)

                Digilys.datatables.saveState(state, url)
        )

        if tableState.fixedColumns
            new jQuery.fn.dataTable.FixedColumns(
                dataTable,
                sHeightMatch:  "none"
                iLeftColumns:  tableState.fixedColumns
                iRightColumns: 0
            )

        # Filter the table by groups
        groupSelector = $("#color-table-group-selector")

        # A change just refreshes the table
        groupSelector.select2().on "change", -> dataTable.fnDraw()

        # Filter rows depending on the groups
        jQuery.fn.dataTableExt.afnFiltering.push (settings, columns, columnIdx) ->
            filter = (parseInt(i) for i in groupSelector.val() || [])

            if filter.length < 1
                return true

            # The row's groups is contain in the data-groups attribute of the link
            # in the first column
            groups = $(columns[0]).data("groups")

            for i in filter
                return true if groups.indexOf(i) >= 0

            return false

        $(".filter input", colorTable).on "keyup", ->
            $input = $(this)
            dataTable.fnFilter($input.val(), $input.closest("tr").find("input").index(this))

        # Toggle between different values in the result table
        $(".result-toggles").on "click", ".btn:not(.active)", ->
            button = $(this)

            # Switch to the clicked button
            button.addClass "active"
            button.siblings().removeClass "active"

            # Change which value is displayed by replacing the CSS class
            colorTable.attr "class", (i, cls) ->
                cls.replace /color-table-show-\w+/, "color-table-show-#{button.data("value")}"

            # Store the state globally
            Digilys.currentResult = button.data("value")

        # Close popovers when clicking outside a popover
        Digilys.bindPopoverCloser($("body"))

        # Single popovers in the color table
        new Digilys.SinglePopover colorTable,
            content: ->
                trigger = $(this)

                switch trigger.data("type")
                    # Student details popover
                    when "student"
                        return trigger.siblings(".student-details-popover-table").clone().show()
                    # Column menu popover
                    when "column-menu"
                        columnIndex = Digilys.datatables.columnIndex(dataTable, trigger)
                        columnIndex ?= trigger.closest("th").index()

                        return new Digilys.ColumnMenu(
                            dataTable,
                            columnIndex,
                            "#color-table-column-popup",
                            beforeAction: -> trigger.popover("destroy")
                            locked: trigger.closest(".DTFC_LeftWrapper").length > 0
                        ).menu

