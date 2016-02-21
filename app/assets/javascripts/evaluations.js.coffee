$ ->
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

            new Digilys.StanineRangeEntry(
                form: $form
                min: ".stanine-field-min"
                max: ".stanine-field-max"
            )

        # Hide/show different value fields
        $("#evaluation_value_type").on "change", ->
            $form.find(".value-type-fields").hide()
            $form.find("." + $(this).val() +  "-fields").show()

    $(".evaluation-template-autocomplete-field").each ->
        autocomplete = new Digilys.DescriptionAutocomplete($(this))
