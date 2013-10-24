###
Triggers a boolean field if the value of a field is blank or not.

This can be used to trigger the Rails *__destroy field to indicate
that a child record should be destroyed.
###

class BlankTrigger
    constructor: (options) ->
        @form          = $(options.form)
        @inputs        = options.inputs
        @triggerSuffix = options.triggerSuffix
        @booleanSuffix = options.booleanSuffix

        self = this

        @form.on "change", @inputs, -> self.change(this)

    change: (field) ->
        boolean = $("#" + field.id.replace(@triggerSuffix, @booleanSuffix))

        if boolean.length == 1
            value = $.trim($(field).val())

            if value.length > 0
                boolean.val("0")
            else
                boolean.val("1")


# Export
window.Digilys ?= {}
window.Digilys.BlankTrigger = BlankTrigger
