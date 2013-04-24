$ ->
    $("#new_evaluation").each ->
        # Update the values in the red and green ranges
        # when the max result, red below or green above
        # fields change
        $maxResult  = $("#evaluation_max_result")
        $redBelow   = $("#evaluation_red_below")
        $greenAbove = $("#evaluation_green_above")

        $redMax     = $("#evaluation-red-max")
        $greenMin   = $("#evaluation-green-min")
        $greenMax   = $("#evaluation-green-max")
        $stanineMax = $("#evaluation-stanine-max")

        $maxResult.on "change", ->
            try
                value = parseInt($maxResult.val())
                $greenMax.val(value)
                $stanineMax.val(value)
            catch err
                $greenMax.val(0)

        $redBelow.on "change", ->
            try
                $redMax.val(parseInt($redBelow.val()) - 1)
            catch err
                $redMax.val(0)

        $greenAbove.on "change", ->
            try
                $greenMin.val(parseInt($greenAbove.val()) + 1)
            catch err
                $greenMin.val(0)

        # Update the lower boundary indicator of stanine fields
        # when the stanine fields change
        $(this).on "change", ".stanine-field", ->
            $field = $(this)
            $target = $field.closest(".control-group").next(".control-group").find(".stanine-below")

            try
                $target.text(parseInt($field.val()) + 1)
            catch err
                $target.text("")
