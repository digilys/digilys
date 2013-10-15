###
Adds a load mask to an element, making the element
unclickable
###
class LoadMask
    constructor: (@elem) ->
        @elem.css    "position", "relative"
        @elem.append '<div class="load-mask"/>'
        @elem.data   "LoadMask", this

    disable: ->
        @elem.children(".load-mask").remove()

# Export
window.Digilys ?= {}
window.Digilys.LoadMask = LoadMask
