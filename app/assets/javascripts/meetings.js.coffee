$ ->
    # Dynamically add more fields for activites when the last fields become used
    $("#meeting-report-form").each ->
        $form = $(this)
        $activitiesContainer = $form.find(".activities-fields:first")
        template = $activitiesContainer.find("fieldset.inputs:first").html()
            .replace(/([_\[])0([_\]])/gi, "$1{{idx}}$2")

        tinymceCode = $activitiesContainer.data("tinymce")

        buildFields = (index) ->
            fieldHtml = template.replace(/\{\{idx\}\}/gi, index.toString())
            $fields = $("<fieldset/>").addClass("inputs").append($(fieldHtml))
            $fields.find(":text, textarea").val("")
            $fields.find(".select2-container").remove()

            $fields.find(".activity-students-autocomplete-field").each ->
                $field = $(this)
                $field.data("data", null).val("")
                new Digilys.StudentGroupAutocomplete($field)

            $fields.find(".user-autocomplete-field").each ->
                $field = $(this)
                $field.data("data", null).val("")
                new Digilys.Autocomplete($field, "name_or_email_cont")

            $fields

        $activitiesContainer.on "click", ".add-activity-action", (event) ->
            event.preventDefault()
            $fields = buildFields($activitiesContainer.find("fieldset.inputs").length)
            $form.find(".tinymce").removeClass("tinymce")
            $activitiesContainer.find("fieldset.inputs:last").after($fields)
            $fields.find("input.datepicker").datepicker(
                language:  "sv"
                format:    "yyyy-mm-dd"
                weekStart: 1
                autoclose: true
            )
            eval(tinymceCode)
