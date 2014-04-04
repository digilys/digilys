describe "Digilys.BlankTrigger", ->
    form         = null
    trigger      = null
    boolean      = null
    blankTrigger = null

    beforeEach ->
        form    = $("<form/>")
        trigger = $('<input id="test_value"/>')
        boolean = $('<input id="test__destroy"/>')

        form.append(trigger).append(boolean)

        blankTrigger = new Digilys.BlankTrigger
            form:          form
            inputs:        ":input[id=test_value]"
            triggerSuffix: "_value"
            booleanSuffix: "__destroy"


    describe "constructor", ->
        it "correctly assigns the arguments", ->
            expect(blankTrigger.form).toEqual          form
            expect(blankTrigger.inputs).toEqual        ":input[id=test_value]"
            expect(blankTrigger.triggerSuffix).toEqual "_value"
            expect(blankTrigger.booleanSuffix).toEqual "__destroy"

        it "binds a change listener on the form, with the inputs as a filter", ->
            spyOn(blankTrigger, "change")

            trigger.trigger("change")
            boolean.trigger("change")

            expect(blankTrigger.change.calls.count()).toEqual 1

        it "calls the change method with the field that was changed", ->
            theField = null
            blankTrigger.change = (field) ->
                theField = field

            trigger.trigger("change")
            expect(theField.id).toEqual trigger.attr("id")


    describe ".change()", ->
        beforeEach -> form.appendTo($("body"))
        afterEach  -> form.remove()

        it "changes the boolean field's value to 1 if the trigger's value is a blank string", ->
            trigger.val("")
            trigger.trigger("change")

            expect(boolean.val()).toEqual "1"

        it "changes the boolean fields' value to 0 if the trigger's value is not a blank string", ->
            trigger.val("zomg")
            trigger.trigger("change")

            expect(boolean.val()).toEqual "0"

        it "does nothing if the boolean field can't be found", ->
            form.remove()

            trigger.val("zomg")
            trigger.trigger("change")

            expect(boolean.val()).toEqual ""
