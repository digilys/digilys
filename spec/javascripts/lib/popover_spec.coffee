describe "Digilys.SinglePopover", ->
    context = null

    create = (options = {}) -> new Digilys.SinglePopover(context, options)

    beforeEach ->
        context = $("<div/>")

    describe "constructor", ->
        it "correctly assigns the arguments", ->
            popover = create()

            expect(popover.context).toBe    context
            expect(popover.options).toEqual {}

        it "adds a popover to the context", ->
            popover = create()
            expect(popover.context).toHaveData("popover")

        it "adds default options to the popover", ->
            popover = create()
            options = popover.context.data("popover").options

            expect(options.html).toBe         true
            expect(options.container).toEqual "body"
            expect(options.selector).toEqual  "[data-toggle=single-popover]"

            trigger = $("<a/>").data("title", "zomg")

            expect(options.title.call(trigger)).toEqual "zomg"

        it "is possible to override default options", ->
            popover = create(html: false, container: "head")
            options = popover.context.data("popover").options

            expect(options.html).toBe         false
            expect(options.container).toEqual "head"

        it "binds a callback to the hidden event which clears the previous", ->
            popover = create()
            popover.previous = {}
            context.trigger("hidden")
            expect(popover.previous).toBeNull()

    describe ".hidePrevious()", ->
        popover  = null
        previous = null

        beforeEach ->
            popover = create()

            previous = { popover: -> }
            spyOn(previous, "popover")

        it "is bound to the shown event on the context", ->
            spyOn(popover, "hidePrevious")
            popover.context.trigger("shown")

            expect(popover.hidePrevious).toHaveBeenCalled()
            expect(popover.hidePrevious.mostRecentCall.object).toBe(popover)

        it "registers the shown event's target as the previous target", ->
            popover.hidePrevious(target: '<div class="previous-target"/>')
            expect(popover.previous).toHaveClass("previous-target")

        it "hides the previous popover", ->
            popover.previous = previous

            popover.hidePrevious(target: "<div/>")
            expect(previous.popover).toHaveBeenCalledWith("hide")

        it "does nothing when the event is undefined", ->
            popover.previous = previous
            popover.hidePrevious()
            expect(previous.popover).not.toHaveBeenCalledWith("hide")


describe ".bindPopoverCloser()", ->
    context      = null
    trigger      = null
    otherTrigger = null
    dummy        = null

    beforeEach ->
        context = $("<div/>")

        trigger = $("<a data-toggle='popover' data-title='foo' data-content='bar'/>")
        context.append(trigger)
        otherTrigger = $("<a data-toggle='popover'/>")
        context.append(otherTrigger)

        dummy = $("<a/>")
        context.append(dummy)

        trigger.popover().popover("show")

        Digilys.bindPopoverCloser(context)

    it "adds a click handler to the context", ->
        events = $._data(context.get(0), "events")

        expect(events.click).toBeDefined()
        expect(events.click.length).toEqual 1
        expect(events.click[0].namespace).toEqual "data-api.popover"

    it "closes the popover when clicking outside the popover", ->
        dummy.trigger("click")
        expect(context.find(".popover.in").length).toBe 0

    it "does not close the popover when clicking in the popover", ->
        $(".popover-content").trigger("click")
        expect(context.find(".popover.in").length).toBe 1

    it "does not close the popover when clicking another popover", ->
        otherTrigger.trigger("click")
        expect(context.find(".popover.in").length).toBe 1

    it "does not call the popover method for triggers that do not already have a popover", ->
        dummy.trigger("click")
        expect(otherTrigger).not.toHaveData("popover")
