$ ->
    $(".suite-template-autocomplete-field").each ->
        autocomplete = new Digilys.Autocomplete($(this))
        autocomplete.enableAutosubmit("form")

    $("#new_suite #suite_is_template").on "change", ->
        if ($(this).is(":checked"))
            $("#new_participant").hide()
        else
            $("#new_participant").show()

    resultTable = $(".suite-results").dataTable(
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
            domIds = $.makeArray($(this).find("thead tr:first th").map -> this.id)
            return window.Digilys.datatables.processStateForLoading(this.data("table-state"), domIds)
        fnStateSave: (settings, state) ->
            state = window.Digilys.datatables.processStateForSaving(state, this.fnSettings().aoColumns)

            url = this.data("save-local-state-path")
            this.data("current-state", state)

            window.Digilys.datatables.saveState(state, url)
    )

    # Filter the table by groups
    $groupSelector = $("#suite-group-selector")

    if $groupSelector.length > 0

        # A change just refreshes the table
        $groupSelector.select2().on "change", ->
            resultTable.fnDraw()

        # Filter rows depending on the groups
        window.jQuery.fn.dataTableExt.afnFiltering.push (settings, columns, columnIdx) ->
            filter = (parseInt(i) for i in $groupSelector.val() || [])

            if filter.length < 1
                return true

            # The row's groups is contain in the data-groups attribute of the link
            # in the first column
            groups = $(columns[0]).data("groups")

            for i in filter
                return true if groups.indexOf(i) >= 0

            return false

    $(".suite-results .filter input").on "keyup", ->
        $input = $(this)
        resultTable.fnFilter($input.val(), $input.closest("tr").find("input").index(this))

    # Toggle between different values in the result table
    $(".result-toggles").on "click", ".btn:not(.active)", ->
        $button = $(this)

        # Switch to the clicked button
        $button.addClass "active"
        $button.siblings().removeClass "active"

        # Change which value is displayed by replacing the CSS class
        $(".suite-results").attr "class", (i, cls) ->
            cls.replace /suite-show-\w+/, "suite-show-#{$button.data("value")}"

        # Store the state globally
        window.Digilys.currentResult = $button.data("value")

    # Display a popover of student data
    addedCloseHandler = false

    $(".suite-results a.student").each ->
        $trigger = $(this)
        $trigger.popover(
            html: true
            content: ->
                # popover requires the content as a string, so we convert the
                # table from the sibling markup to text
                # http://stackoverflow.com/a/8127137
                return $(this).siblings(".student-details-popover-table").clone().show().wrap("<div/>").parent().html()
        )
        $trigger.click (e) ->
            e.preventDefault()
            $(".suite-results a.student").not(this).popover("hide")

        if !addedCloseHandler
            $("html").on "click.popover.data-api", (event) ->
                $target = $(event.target)

                if $target.data("toggle") != "popover" && $target.closest(".popover").length == 0
                    $(".suite-results a.student").popover("hide")

            addedCloseHandler = true

    # Handle column removal. This just hijacks any link and triggers the Rails
    # delete action, and has to be done because there is no way to prevent dataTables
    # from doing a sort even if the user clicks a link inside a sortable header
    $(".suite-results .remove-column-action").on "click", (event) ->
        event.preventDefault()
        $.rails.handleMethod($(this))
        return false


    $(".suite-users-table").each ->
        new Digilys.RemoteToggleList(this, "user_ids")

    $(".evaluation-status-progress[title]").tooltip(
        html:      true
        placement: "right"
        delay:     { show: 300, hide: 100 }
    )

