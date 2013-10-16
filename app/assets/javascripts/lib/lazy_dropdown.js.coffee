###
Creates a dropdown which lazily loads the dropdown
contents when clicking the toggler
###
class LazyDropdown
    constructor: (@toggler) ->
        @toggler.one "click", => @loadDropdown()

    loadDropdown: ->
        $.get @toggler.attr("href"), (html, textStatus, xhr) =>
            @setMenu(html)

    setMenu: (html) ->
        @toggler.siblings(".dropdown-menu").find(".load-indicator").replaceWith(html)

# Export
window.Digilys ?= {}
window.Digilys.LazyDropdown = LazyDropdown
