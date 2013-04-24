$ ->
    $("#evaluation-form").each ->
        $form = $(this)

        # Transform a string to an int, returning
        # 0 if the parsed value is not valid
        #
        # With +change+, you can change the value returned
        intify = (value, change = 0) ->
            try
                value = parseInt(value)
                return if isNaN(value) then 0 else value + change
            catch err
                return 0

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
            value = intify($maxResult.val())
            $greenMax.val(value)
            $stanineMax.val(value)

        $redBelow.on "change", ->
            $redMax.val(intify($redBelow.val(), -1))

        $greenAbove.on "change", ->
            $greenMin.val(intify($greenAbove.val(), 1))

        $maxResult.trigger("change")
        $redBelow.trigger("change")
        $greenAbove.trigger("change")

        # Update the lower boundary indicator of stanine fields
        # when the stanine fields change
        $form.on "change", ".stanine-field", ->
            $field = $(this)
            $target = $field.closest(".control-group").next(".control-group").find(".stanine-below")
            $target.text(intify($field.val(), 1))

        $form.find(".stanine-field").trigger("change")
