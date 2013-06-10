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

        if this.id.match(/evaluation_results_attributes_\d+_value/)
            destroyId     = this.id.replace("_value", "__destroy")
            $destroyInput = $("#" + destroyId)

            if $destroyInput.length == 1
                value = $.trim($(this).val())

                if value.length > 0
                    $destroyInput.val("0")
                else
                    $destroyInput.val("1")
