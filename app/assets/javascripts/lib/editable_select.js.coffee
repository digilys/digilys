###
Creates a select2 select box where you can select a
single value, or create a new by writing a value.
###
class EditableSelect
    constructor: (@elem) ->
        @elem.each (i, elem) =>
            elem = $(elem)

            elem.select2
                allowClear:         true
                placeholder:        elem.data("placeholder")
                data:               elem.data("data")
                createSearchChoice: => @buildChoice.apply(this, arguments)

    buildChoice: (term, data) ->
        for id, text of data
            return null if text == term
        return { id: term, text: term }

# Export
window.Digilys ?= {}
window.Digilys.EditableSelect = EditableSelect
