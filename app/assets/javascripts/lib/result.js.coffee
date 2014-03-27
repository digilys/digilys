window.Digilys ?= {}

###
Form validator that checks that a result is between the min and the
max result, showing an error message if not.
###

class ResultValidator
    constructor: (@form) ->
        self = this
        @form.on "change", "input[type=number]", -> self.validate($(this))

    validate: (field) ->
        min = parseInt(field.attr("min"))
        max = parseInt(field.attr("max"))

        try
            value = parseInt(field.val())

            if value > max || value < min
                @addError(field)
            else
                @removeError(field)
        catch err
            @addError(field)

    addError: (field) ->
        container = field.closest(".control-group")

        unless container.hasClass("error")
            container.addClass("error")
            field.after($("<span/>").addClass("help-inline").text(field.data("error-message")))

    removeError: (field) ->
        field.closest(".control-group").removeClass("error")
        field.siblings("span.help-inline").remove()

# Export
window.Digilys.ResultValidator = ResultValidator

###
Updates input fields for destroying results when leaving
the result's values blank
###

class ResultDestroyer
    constructor: (@form) ->
        self = this
        @form.on "change", ":input", -> self.updateDestroyFlag($(this))

    updateDestroyFlag: (field) ->
        id = field.attr("id")
        return if !id || !id.match(/_(value|absent)$/)

        id = id.replace(/_(value|absent)$/, "")

        destroy = $("##{id}__destroy")

        return unless destroy.length == 1

        value  = $.trim($("##{id}_value").val())
        absent = $("##{id}_absent").is(":checked")

        if value.length > 0 || absent
            destroy.val("0")
        else
            destroy.val("1")


# Export
window.Digilys.ResultDestroyer = ResultDestroyer
