###
Provides functionality for entering the color ranges for an evaluation.

The entering works by having dummy text fields where the user enters a
single range, the middle one, which both updates a display of the range
above and below as well as the actual inputs where the ranges are stored
for submission.

The reason for having dummy display fields is that the range can be entered
as percentages, and instead of having the backend do the conversion, the
conversion is done in JS by this class.

It is also possible to enter the range in reverse order to flip the order
of the ranges.
###
class ColorRangeEntry

    ###
    # Arguments are supplied as an object with the following format:
    #
    # max:      "selector for the max input"
    # red:
    #   min:    "selector for the red minimum input"
    #   max:    "selector for the red maximum input"
    # yellow:
    #   min:    "selector for the yellow minimum input"
    #   max:    "selector for the yellow maximum input"
    # green:
    #   min:    "selector for the green minimum input"
    #   max:    "selector for the green maximum input"
    # text:
    #   red:
    #     min:  "selector for the red minimum dummy input"
    #     max:  "selector for the red maximum dummy input"
    #   yellow:
    #     min:  "selector for the yellow minimum dummy input"
    #     max:  "selector for the yellow maximum dummy input"
    #   green:
    #     min:  "selector for the green minimum dummy input"
    #     max:  "selector for the green maximum dummy input"
    ###
    constructor: (selectors) ->
        @fields =
            max: $(selectors.max)
            red:
                min: $(selectors.red.min)
                max: $(selectors.red.max)
            yellow:
                min: $(selectors.yellow.min)
                max: $(selectors.yellow.max)
            green:
                min: $(selectors.green.min)
                max: $(selectors.green.max)
            text:
                red:
                    min: $(selectors.text.red.min)
                    max: $(selectors.text.red.max)
                yellow:
                    min: $(selectors.text.yellow.min)
                    max: $(selectors.text.yellow.max)
                green:
                    min: $(selectors.text.green.min)
                    max: $(selectors.text.green.max)

        @fields.max.on             "change", => @update()
        @fields.text.yellow.min.on "change", => @update()
        @fields.text.yellow.max.on "change", => @update()

        # Flip values if there are existing reordered ranges
        if parseInt(@fields.yellow.min.val()) < parseInt(@fields.red.min.val())

            ymin = @fields.text.yellow.min.val()
            ymax = @fields.text.yellow.max.val()

            @fields.text.yellow.min.val(ymax)
            @fields.text.yellow.max.val(ymin)

            @update()

    update: ->
        max   = parseInt(@fields.max.val())
        ymin  = @fields.text.yellow.min.val()
        range =
            min: parseInt(ymin)
            max: parseInt(@fields.text.yellow.max.val())

        percentage = if /%/.test(ymin) then true else false
        reverse    = false

        if range.max < range.min
            reverse = true
            [range.min, range.max] = [range.max, range.min]

        @updateText(  max, range, reverse, percentage)
        @updateValues(max, range, reverse, percentage)

    updateText: (max, range, reverse, percentage) ->
        if reverse
            lower = from: @fields.text.green.max, to: @fields.text.green.min
            upper = from: @fields.text.red.max,   to: @fields.text.red.min
        else
            lower = from: @fields.text.red.min,   to: @fields.text.red.max
            upper = from: @fields.text.green.min, to: @fields.text.green.max

        # Default values
        lower.from_value = null
        lower.to_value   = null
        upper.from_value = null
        upper.to_value   = null

        max              = if percentage then 100 else max

        if max > 0 && !isNaN(range.min) && !isNaN(range.max)

            if range.min > 0
                lower.from_value = 0
                lower.to_value   = range.min - 1

            if range.max < max
                upper.from_value = range.max + 1
                upper.to_value   = max

        suffix    = if percentage then "%" else ""

        # Persist values in the DOM
        lower.from.val @addSuffix(lower.from_value, suffix)
        lower.to.val   @addSuffix(lower.to_value,   suffix)
        upper.from.val @addSuffix(upper.from_value, suffix)
        upper.to.val   @addSuffix(upper.to_value,   suffix)

    updateValues: (max, range, reverse, percentage) ->
        range.from = @fields.yellow.min
        range.to   = @fields.yellow.max

        if reverse
            lower = from: @fields.green.min, to: @fields.green.max
            upper = from: @fields.red.min,   to: @fields.red.max
        else
            lower = from: @fields.red.min,   to: @fields.red.max
            upper = from: @fields.green.min, to: @fields.green.max

        # Default values
        lower.from_value = ""
        lower.to_value   = ""
        range.from_value = ""
        range.to_value   = ""
        upper.from_value = ""
        upper.to_value   = ""

        if max > 0 && !isNaN(range.min) && !isNaN(range.max)

            if percentage
                range.min = (range.min / 100) * max
                range.max = (range.max / 100) * max

            range.from_value = range.min
            range.to_value   = range.max

            if range.min > 0
                lower.from_value = 0
                lower.to_value   = range.min - 1

            if range.max < max
                upper.from_value = range.max + 1
                upper.to_value   = max

        # Persist values in the DOM
        lower.from.val lower.from_value
        lower.to.val   lower.to_value
        range.from.val range.from_value
        range.to.val   range.to_value
        upper.from.val upper.from_value
        upper.to.val   upper.to_value

    addSuffix: (value, suffix) ->
        if value != null
            value.toString() + suffix
        else
            ""

# Export
window.Digilys ?= {}
window.Digilys.ColorRangeEntry = ColorRangeEntry
