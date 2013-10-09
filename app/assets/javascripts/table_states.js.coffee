$ ->
    $tableStateList     = $("#table-states")
    $tableStateSelector = $("#table-state-selector")

    $tableStateSelector.on "change", (event) ->
        event.preventDefault()

        try
            stateId = parseInt($tableStateSelector.val())
        catch error
            stateId = 0

        if stateId > 0
            urlTemplate = $tableStateSelector.data("url")
            $tableStateSelector.attr("disabled", "disabled")
            window.location.href = urlTemplate.replace(":id", stateId)
        else if stateId == 0
            url = $tableStateSelector.data("clear-url")

            $dummyLink = $("a").attr("href", url)
            $dummyLink.data("method", "delete")
            $.rails.handleMethod($dummyLink)

            $tableStateSelector.attr("disabled", "disabled")

    $("#save-table-state").on "click", (event) ->
        event.preventDefault()

        $trigger = $(this)
        $nameContainer = $trigger.siblings("#table-state-name")

        name = $.trim($nameContainer.val())

        if name != ""
            $trigger.button("loading")

            url        = $trigger.data("url")
            tableState = $($trigger.data("datatable")).data("current-state")

            $.ajax(
                url:    url
                method: "POST"
                data:
                    table_state:
                        name: name,
                        data: JSON.stringify(tableState)

                success: (data, status, xhr) ->
                    $nameContainer.val("")

                    # Add the the new state to the selector dropdown
                    if $tableStateSelector.find("option[value=#{data.id}]").length <= 0
                        $tableStateSelector.append($("<option value=\"#{data.id}\">#{data.name}</option>"))

                    # Add the new state to the list of states
                    if $tableStateList.find("tr[data-id=#{data.id}]").length <= 0
                        $row = $("<tr/>")
                        $row.attr("data-id", data.id)

                        # First cell contains the link for selecting the state
                        $("<td/>").append(
                            $("<a/>")
                                .attr("href", data.urls.select)
                                .text(data.name)
                        ).appendTo($row)

                        # Second cell contains the link for destroying the state
                        $("<td/>").append(
                            $("<a/>")
                                .attr("href", data.urls.default)
                                .addClass("btn btn-small btn-danger")
                                .attr("data-method", "delete")
                                .attr("data-remote", "true")
                                .attr("rel", "nofollow")
                                .text($tableStateList.data("delete-action-name"))
                        ).appendTo($row)

                        $tableStateList.find("tbody").prepend($row)

                complete: ->
                    $trigger.button("reset")
            )

    # Removes the table state info after it has been deleted by a remote call
    $tableStateList.on "ajax:success", (event, data) ->
        # Row in listing
        $(event.target).closest("tr").remove()
        # Option in selector
        $tableStateSelector.find("option[value=#{data.id}]").remove()
