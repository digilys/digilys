$ ->
    # Toggle between different values in the result table
    $(".suite-results .result-toggles").on "click", ".btn:not(.active)", ->
        $button = $(this)

        # Switch to the clicked button
        $button.addClass "active"
        $button.siblings().removeClass "active"

        # Change which value is displayed by replacing the CSS class
        $button.closest(".suite-results").attr "class", (i, cls) ->
            cls.replace /suite-show-\w+/, "suite-show-#{$button.data("value")}"
