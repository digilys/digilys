$ ->
    intify = (value) ->
        try
            value = parseInt(value)
            return if isNaN(value) then 0 else value
        catch err
            return 0

    addSuffix = (value, suffix) ->
        if value != null
            value.toString() + suffix
        else
            ""

    $("#evaluation-form").each ->
        $form = $(this)

        $maxResult     = $("#evaluation_max_result")
        $redMinText    = $("#evaluation_red_min_text")
        $redMaxText    = $("#evaluation_red_max_text")
        $yellowMinText = $("#evaluation_yellow_min_text")
        $yellowMaxText = $("#evaluation_yellow_max_text")
        $greenMinText  = $("#evaluation_green_min_text")
        $greenMaxText  = $("#evaluation_green_max_text")
        $redMin        = $("#evaluation_red_min")
        $redMax        = $("#evaluation_red_max")
        $yellowMin     = $("#evaluation_yellow_min")
        $yellowMax     = $("#evaluation_yellow_max")
        $greenMin      = $("#evaluation_green_min")
        $greenMax      = $("#evaluation_green_max")

        $maxResult.on "change", ->
            $form.trigger("color-range-change")

        $yellowMinText.on "change", ->
            $form.trigger("color-range-change")
        $yellowMaxText.on "change", ->
            $form.trigger("color-range-change")

        # Update color ranges whenever ranges change
        $form.on "color-range-change", ->
            yellowMin = $yellowMinText.val()
            yellowMax = $yellowMaxText.val()

            suffix    = if /%/.test(yellowMin) then "%" else ""

            yellowMin = intify(yellowMin)
            yellowMax = intify(yellowMax)

            maxResult = if suffix.length > 0 then 100 else intify($maxResult.val())

            if yellowMin <= yellowMax
                # When the yellow range is entered in ascending
                # order, the red range is below the yellow and the green
                # above
                ranges =
                    red:    { min: null,      max: null }
                    yellow: { min: yellowMin, max: yellowMax }
                    green:  { min: null,      max: null }
                
                ranges.red   = { min: 0,             max: yellowMin - 1 } if yellowMin > 0
                ranges.green = { min: yellowMax + 1, max: maxResult }     if yellowMax < maxResult
                
            else
                # When the yellow range is entered in the reverse order,
                # the ranges should change so the red range is above
                # the yellow range rather than below, and the green is below
                # rather than above
                ranges =
                    red:    { min: null,      max: null }
                    yellow: { min: yellowMax, max: yellowMin }
                    green:  { min: null,      max: null }
                
                ranges.red   = { min: maxResult,     max: yellowMin + 1 } if yellowMin < maxResult
                ranges.green = { min: yellowMax - 1, max: 0 }             if yellowMax > 0

            # Update the dummy display ranges
            $redMinText.val(  addSuffix(ranges.red.min,   suffix))
            $redMaxText.val(  addSuffix(ranges.red.max,   suffix))
            $greenMinText.val(addSuffix(ranges.green.min, suffix))
            $greenMaxText.val(addSuffix(ranges.green.max, suffix))

            # Convert percentage ranges to normal ranges
            if suffix.length > 0
                maxResult = intify($maxResult.val())

                ranges =
                    yellow:
                        min: (ranges.yellow.min / 100) * maxResult
                        max: (ranges.yellow.max / 100) * maxResult

                # Recalculate the red and green ranges base on the real yellow values,
                # otherwise, the ranges might have gaps or overlapping depending on
                # the rounding of the percentages
                if yellowMin <= yellowMax
                    ranges.red   = { min: 0,                     max: ranges.yellow.min - 1 } if ranges.yellow.min > 0
                    ranges.green = { min: ranges.yellow.max + 1, max: maxResult }             if ranges.yellow.max < maxResult
                else
                    ranges.red   = { min: maxResult,             max: ranges.yellow.max + 1 } if ranges.yellow.max < maxResult
                    ranges.green = { min: ranges.yellow.min - 1, max: 0 }                     if ranges.yellow.min > 0

            # Update the hidden fields that are actually submitted
            # They are always in the correct order, meaning min <= max
            $yellowMin.val(Math.min(ranges.yellow.min, ranges.yellow.max))
            $yellowMax.val(Math.max(ranges.yellow.min, ranges.yellow.max))

            # Handle empty values
            if ranges.red && ranges.red.min != null && ranges.red.max != null
                $redMin.val(Math.min(ranges.red.min, ranges.red.max))
                $redMax.val(Math.max(ranges.red.min, ranges.red.max))
            else
                $redMin.val("")
                $redMax.val("")

            if ranges.green && ranges.green.min != null && ranges.green.max != null
                $greenMin.val(Math.min(ranges.green.min, ranges.green.max))
                $greenMax.val(Math.max(ranges.green.min, ranges.green.max))
            else
                $greenMin.val("")
                $greenMax.val("")

        $form.on "change", ".stanine-field-max", ->
            $form.find(".stanine-field-max").each ->
                $maxField = $(this)

                value = $maxField.val()
                value = if value.length > 0 then intify(value) else null

                stanine = $maxField.data("stanine")

                # Set lower limit
                if value
                    lowerLimit = 0

                    if stanine > 1
                        $form.find(".stanine-field-max").slice(0, stanine - 1).each ->
                            v = $(this).val()
                            lowerLimit = intify(v) + 1 if v.length > 0

                    $maxField.siblings(".stanine-field-min").val(Math.min(lowerLimit, value))
                else
                    $maxField.siblings(".stanine-field-min").val("")

        # If we load a form with reverse order colors, flip the
        # values in the yellow fields
        if intify($yellowMin.val()) < intify($redMin.val())
            yellowMinTextVal = $yellowMinText.val()
            yellowMaxTextVal = $yellowMaxText.val()
            $yellowMinText.val(yellowMaxTextVal)
            $yellowMaxText.val(yellowMinTextVal)
            $form.trigger("color-range-change")

        # Hide/show different value fields
        $("#evaluation_value_type").on "change", ->
            $form.find(".value-type-fields").hide()
            $form.find("." + $(this).val() +  "-fields").show()

    $(".evaluation-template-autocomplete-field").each ->

        window.Digilys.autocomplete(
            this,
            data: (term, page) ->
                { q: { name_or_description_cont: term }, page: page }
            formatResult: (result, container, query, escapeMarkup) ->
                nameMarkup = []
                window.Select2.util.markMatch(result.name || "", query.term, nameMarkup, escapeMarkup)

                descriptionMarkup = []
                window.Select2.util.markMatch(result.description || "", query.term, descriptionMarkup, escapeMarkup)

                return nameMarkup.join("") + '<small>' + descriptionMarkup.join("") + "</small>"
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
