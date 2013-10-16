###
Enables a warning on a form if the form has beeen changed and the user
navigates away from the page

Includes support for bypassing the warning.
###
class WarnableForm
    constructor: (@form, @confirmation) ->
        @form.on "change", ":input", (event) => @change(event)
        @form.on "submit",           (event) => @submit(event)

    change: (event) ->
        if !$(event.target).data("preventNavigationConfirmation")
            window.onbeforeunload = => @confirmation

    submit: (event) ->
        window.onbeforeunload = null

# Export
window.Digilys ?= {}
window.Digilys.WarnableForm = WarnableForm
