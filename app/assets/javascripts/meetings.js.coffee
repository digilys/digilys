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

            $fields

        addChangeListener = ->
            $activitiesContainer.find("fieldset.inputs:last").one "change", ":text, textarea", ->
                $fields = buildFields($activitiesContainer.find("fieldset.inputs").length)
                $form.find(".tinymce").removeClass("tinymce")
                $activitiesContainer.append($fields)
                eval(tinymceCode)
                addChangeListener()

        addChangeListener()
