$ ->
    intify = (value) ->
        try
            value = parseInt(value)
            return if isNaN(value) then 0 else value
        catch err
            return 0

    $("#evaluation-form").each ->
        $form = $(this)

        $form.find(".evaluation-participants-autocomplete-field").each ->
            new Digilys.StudentGroupAutocomplete($(this))

        if $form.find(".numeric-fields:first").length > 0
            new Digilys.ColorRangeEntry(
                max: "#evaluation_max_result"
                red:
                    min: "#evaluation_red_min"
                    max: "#evaluation_red_max"
                yellow:
                    min: "#evaluation_yellow_min"
                    max: "#evaluation_yellow_max"
                green:
                    min: "#evaluation_green_min"
                    max: "#evaluation_green_max"
                text:
                    red:
                        min: "#evaluation_red_min_text"
                        max: "#evaluation_red_max_text"
                    yellow:
                        min: "#evaluation_yellow_min_text"
                        max: "#evaluation_yellow_max_text"
                    green:
                        min: "#evaluation_green_min_text"
                        max: "#evaluation_green_max_text"
            )

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

        # Hide/show different value fields
        $("#evaluation_value_type").on "change", ->
            $form.find(".value-type-fields").hide()
            $form.find("." + $(this).val() +  "-fields").show()

    $(".evaluation-template-autocomplete-field").each ->
        autocomplete = new Digilys.DescriptionAutocomplete($(this))
        autocomplete.enableAutosubmit("form")
