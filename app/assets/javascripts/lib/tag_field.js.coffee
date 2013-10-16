###
Creates a select2 field for tagging, loading existing
tags from a data attribute
###
class TagField
    constructor: (@elem) ->
        @elem.each (i, elem) =>
            elem = $(elem)

            tags = elem.data("existing-tags") ? []

            elem.select2
                tags: tags

            if elem.data("autofocus")
                elem.select2 "open"

# Export
window.Digilys ?= {}
window.Digilys.TagField = TagField
