###
Provides functionality for entering the stanine ranges for an evaluation.

The stanine ranges are entered by supplying the upper value of the range,
while the lower value is inferred by any range below the current range.
###
class StanineRangeEntry

    ###
    # Arguments are supplied as an object with the following format:
    #
    # form: "selector/dom object for the form containing the fields"
    # min:  "selector for the stanine range minimum inputs"
    # max:  "selector for the stanine range maximum inputs"
    ###
    constructor: (selectors) ->
        @form = $(selectors.form)
        @min  = selectors.min
        @max  = selectors.max

        @form.on "change", @max, => @update()

    update: ->
        maxs = @form.find(@max)
        maxs.each ->
            max     = $(this)
            val     = max.val()
            stanine = max.data("stanine")
            min     = max.siblings(@min)

            value = ""

            if val.length > 0 && !isNaN(parseInt(val))
                value = 0

                if stanine > 1
                    # Find the value of the closest valid maximum field below
                    # the current
                    maxs.slice(0, stanine - 1).each ->
                        v = $(this).val()
                        value = parseInt(v) + 1 if v.length > 0

                value = Math.min(value, val)

            min.val(value)

# Export
window.Digilys ?= {}
window.Digilys.StanineRangeEntry = StanineRangeEntry
