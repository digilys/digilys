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
