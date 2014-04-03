###
A result entry form validates the result, toggles the destroy flag
and toggles the disabled state when absent
###

class ResultEntryForm
    constructor: (@form) ->
        self = this
        @form.on "change", "input[type=number]", -> self.validate($(this))
        @form.on "change", ":input",             -> self.updateDestroyFlag($(this))
        @form.on "change", ":checkbox",          -> self.toggleValueInput($(this))

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

    toggleValueInput: (checkbox) ->
        id = checkbox.attr("id")
        return if !id || !id.match(/_absent$/)

        id = id.replace(/_absent$/, "_value")

        value = $("##{id}")
        value.prop("disabled", checkbox.is(":checked"))

# Export
window.Digilys ?= {}
window.Digilys.ResultEntryForm = ResultEntryForm
