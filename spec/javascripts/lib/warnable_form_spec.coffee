describe "Digilys.WarnableForm", ->
    input = null
    elem  = null
    form  = null

    beforeEach ->
        input = $("<input/>")
        elem  = $("<form/>").append(input)
        form  = new Digilys.WarnableForm(elem, "my-confirmation")

    afterEach ->
        window.onbeforeunload = null

    it "intercepts change events on the form", ->
        spyOn(form, "change")
        input.trigger("change")
        expect(form.change).toHaveBeenCalled()

    it "intercepts submit events on the form", ->
        spyOn(form, "submit")
        elem.trigger("submit")
        expect(form.submit).toHaveBeenCalled()

    describe "change", ->
        it "enables the warning", ->
            form.change target: $("<input/>")
            expect(window.onbeforeunload()).toEqual "my-confirmation"

        it "does not enable the warning if the target has a data attribute preventing it", ->
            target = $("<input/>")
            target.data("preventNavigationConfirmation", true)

            form.change target: target
            expect(window.onbeforeunload).toBe null

    describe "submit()", ->
        it "disables the warning", ->
            window.onbeforeunload = -> "zomg"
            form.submit {}
            expect(window.onbeforeunload).toBe null
