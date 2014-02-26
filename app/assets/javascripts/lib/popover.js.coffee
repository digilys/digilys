###
Enables a popover that is hidden when other popovers are triggered
###

class SinglePopover
    constructor: (@context, @options) ->
        @context.popover $.extend(
            {
                html:      true
                container: "body"
                selector:  "[data-toggle=single-popover]"
                title:     -> $(this).data("title")
            },
            @options
        )

        @context.on "shown", (event), => @hidePrevious(event)
        @context.on "hidden", => @previous = null

    hidePrevious: (event) ->
        @previous.popover("hide") if @previous
        @previous = $(event.target)

###
Hides all popovers when clicking on something that's not a popover
###

bindPopoverCloser = (context) ->
    context.on "click.popover.data-api", (event) ->
        target = $(event.target)

        if !target.is("[data-toggle$=popover]") && target.closest(".popover").length == 0
            $("[data-toggle$=popover]", context).each ->
                trigger = $(this)
                trigger.popover("hide") if trigger.data("popover")

# Export
window.Digilys ?= {}
window.Digilys.SinglePopover = SinglePopover
window.Digilys.bindPopoverCloser = bindPopoverCloser
