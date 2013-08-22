$ ->
    updateDestroyFlag = (idBase) ->
        $destroyInput = $("##{idBase}__destroy")

        if $destroyInput.length == 1
            $valueInput = $("##{idBase}_value")
            $absentInput = $("##{idBase}_absent")

            value = $.trim($valueInput.val())

            if value.length <= 0 && !$absentInput.is(":checked")
                $destroyInput.val("1")
            else
                $destroyInput.val("0")

    $("#result-entry-form").on "change", "input", ->
        $field = $(this)

        if this.id.match(/evaluation_results_attributes_\d+_value/)
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

            updateDestroyFlag(this.id.replace("_value", ""))

        else if this.id.match(/evaluation_results_attributes_\d+_absent/)

            idBase      = this.id.replace("_absent", "")
            $valueInput = $("##{idBase}_value")

            if $field.is(":checked")
                $valueInput.attr("disabled", "disabled")
            else
                $valueInput.removeAttr("disabled")

            updateDestroyFlag(idBase)

