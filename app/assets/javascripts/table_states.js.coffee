$ ->
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
                    $tableStateSelector.append($("<option value=\"#{data.id}\">#{data.name}</option>"))
                complete: ->
                    $trigger.button("reset")
            )
