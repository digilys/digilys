$ ->
    $(".suite-template-autocomplete-field").each ->
        window.Digilys.autocomplete(
            this,
            data: (term, page) ->
                { q: { name_cont: term }, page: page }
        )
        $field = $(this)


        $field.data("preventNavigationConfirmation", true)
        $field.on "change", (event) ->
            window.Digilys.loadMask($("form"))

            $form = $field.parents("form")

            $submitButton = $form.find(":submit")
            $submitButton.attr("disabled", "disabled")
            $submitButton.val($submitButton.data("loading-text"))

            $form.submit()

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
    )

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
