###
Dynamically add a new set of activity form fields to a form by copying existing
fields as a template and resetting all necessary attributes and functionality.
###

class ActivitiesForm
    constructor: (options) ->
        @form        = $(options.form)
        @container   = @form.find(options.container)
        @activity    = options.activity
        @tinymceCode = @container.data("tinymce")

        @template = @container.find("#{@activity}:first")
            .clone()
            .wrap("<div/>")
            .parent()
            .html()
            .replace(/([_\[])0([_\]])/gi, "$1{{idx}}$2")

        @container.on "click", options.trigger, (event) =>
            event.preventDefault()
            @addFields()

    addFields: ->
        @form.find(".tinymce").removeClass("tinymce")

        fields = @buildFields(@container.find(@activity).length)
        @container.find("#{@activity}:last").after(fields)

        fields.find("input.datepicker").datepicker(
            language:  "sv"
            format:    "yyyy-mm-dd"
            weekStart: 1
            autoclose: true
        )

        eval @tinymceCode


    buildFields: (index) ->
        activity = $(@template.replace(/\{\{idx\}\}/gi, index.toString()))

        activity.find(":text, textarea").val("")
        activity.find(".select2-container").remove()

        activity.find(".activity-students-autocomplete-field").each ->
            field = $(this)
            field.data("data", null).val("")
            new Digilys.StudentGroupAutocomplete(field)

        activity.find(".user-autocomplete-field").each ->
            field = $(this)
            field.data("data", null).val("")
            new Digilys.Autocomplete(field, "name_or_email_cont")

        return activity

# Export
window.Digilys ?= {}
window.Digilys.ActivitiesForm = ActivitiesForm
