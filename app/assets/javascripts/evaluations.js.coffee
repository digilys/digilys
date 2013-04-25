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

        # Update the lower boundary indicator of the next
        # stanine field when a stanine field change.
        # Also, update this field's lower boundary if this field's
        # value is the same as the previous, allowing for
        # overlapping stanine ranges
        $stanines = $form.find(".stanine-field")

        $form.on "change", ".stanine-field", ->
            $stanines.each ->
                $field = $(this)
                $group = $field.closest(".control-group")

                # Update the next stanine field's indicator
                $nextIndicator = $group.next(".control-group").find(".stanine-below")
                $nextIndicator.text(intify($field.val(), 1))

                $prevGroup = $group.prev(".control-group")

                if $field.val() == $prevGroup.find(".stanine-field").val()
                    $group.find(".stanine-below").text($prevGroup.find(".stanine-below").text())

        $stanines.trigger("change")
