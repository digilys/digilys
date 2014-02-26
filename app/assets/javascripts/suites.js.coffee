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
        dataTable = $(".data-table", colorTable).dataTable(
            bSortCellsTop: true
            bPaginate:     false
            bInfo:         false
            bStateSave:    true
            aoColumnDefs:  [
                {
                    aTargets: [ "_all" ],
                    sType:    "sort-key"
                }
            ]
            fnStateLoad: (settings) ->
                domIds = $.makeArray(this.find("thead tr:first th").map -> this.id)
                return Digilys.datatables.processStateForLoading(colorTable.data("table-state"), domIds)
            fnStateSave: (settings, state) ->
                state = Digilys.datatables.processStateForSaving(state, this.fnSettings().aoColumns)

                url = colorTable.data("save-local-state-path")
                this.data("current-state", state)

                Digilys.datatables.saveState(state, url)
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

        Digilys.bindPopoverCloser($("body"))

        new Digilys.SinglePopover colorTable,
            content: ->
                trigger = $(this)

                switch trigger.data("type")
                    when "student" then trigger.siblings(".student-details-popover-table").clone().show()


        # Handle column removal. This just hijacks any link and triggers the Rails
        # delete action, and has to be done because there is no way to prevent dataTables
        # from doing a sort even if the user clicks a link inside a sortable header
        $(".remove-column-action", colorTable).on "click", (event) ->
            event.preventDefault()
            $.rails.handleMethod($(this))
            return false

