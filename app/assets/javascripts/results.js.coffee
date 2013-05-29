$ ->
    $("#result-entry-form").on "change", "input", ->
        $field = $(this)

        try
            value = parseInt($field.val())
            max   = parseInt($("#evaluation_max_result").val())

            if value > max or value < 0
                $field.closest(".control-group").addClass("error")
                $field.after($("<span/>").addClass("help-inline").text($field.data("error-message")))
            else
                $field.closest(".control-group").removeClass("error")
                $field.siblings("span.help-inline").remove()
        catch err
            $field.closest(".control-group").addClass("error")
            $field.after($("<span/>").addClass("help-inline").text($field.data("error-message")))
