describe "Digilys.ResultEntryForm", ->
    entryForm     = null
    form          = null
    controlGroups = null
    controls      = null
    values        = null
    absents       = null
    destroys      = null

    beforeEach ->
        form = $("<form/>")
        $(document.body).append(form)

        controlGroups = []
        controls      = []
        values        = []
        absents       = []
        destroys      = []

        for i in [0..1]
            controlGroups[i] = $("<div/>").addClass("control-group")
            controls[i]      = $("<div/>").addClass("controls")
            values[i]        = $("<input type=\"number\" id=\"evaluation_results_attributes_#{i}_value\" min=\"0\" max=\"123\" data-error-message=\"error-message\"/>")
            absents[i]       = $("<input type=\"checkbox\" id=\"evaluation_results_attributes_#{i}_absent\"/>")
            destroys[i]      = $("<input type=\"hidden\" id=\"evaluation_results_attributes_#{i}__destroy\"/>")

            controls[i].append(values[i])
            controls[i].append(absents[i])
            controls[i].append(destroys[i])
            controlGroups[i].append(controls[i])
            form.append(controlGroups[i])

        destroys[1].val("0")

        entryForm = new Digilys.ResultEntryForm(form)

    afterEach ->
        form.remove()

    describe "validation", ->
        it "allows values between 0 and the max value", ->
            values[0].val("1").trigger("change")
            expect(controlGroups[0]).not.toHaveClass("error")
            expect(controls[0].find("span.help-inline")).toHaveLength(0)

        it "displays an error message when entering a value lower than 0", ->
            values[0].val("-1").trigger("change")
            expect(controlGroups[0]).toHaveClass("error")
            expect(controls[0].find("span.help-inline")).toHaveText("error-message")

        it "displays an error message when entering a value greater than the max value", ->
            values[0].val("124").trigger("change")
            expect(controlGroups[0]).toHaveClass("error")
            expect(controls[0].find("span.help-inline")).toHaveText("error-message")

        it "clears error messages when re-entering a valid value", ->
            values[0].val("-1").trigger("change")
            expect(controlGroups[0]).toHaveClass("error")
            expect(controls[0].find("span.help-inline")).toHaveLength(1)

            values[0].val("").trigger("change")
            expect(controlGroups[0]).not.toHaveClass("error")
            expect(controls[0].find("span.help-inline")).toHaveLength(0)

        it "only adds error changes once", ->
            values[0].val("-1").trigger("change")
            values[0].val("-1").trigger("change")
            expect(controlGroups[0]).toHaveClass("error")
            expect(controls[0].find("span.help-inline")).toHaveLength(1)

        it "only validates number inputs", ->
            other = $('<input type="checkbox" value="-1"/>')
            controls[0].append(other)
            other.trigger("change")
            expect(controlGroups[0]).not.toHaveClass("error")
            expect(controls[0].find("span.help-inline")).toHaveLength(0)

    describe "destroy toggling", ->
        afterEach ->
            expect(destroys[1]).toHaveValue("0")

        it "sets the destroy input to 1 if value is blank and absent is unchecked", ->
            destroys[0].val("0")
            values[0].trigger("change")
            expect(destroys[0]).toHaveValue("1")

            destroys[0].val("0")
            absents[0].trigger("change")
            expect(destroys[0]).toHaveValue("1")
            expect(destroys[1]).toHaveValue("0")

        it "sets the destroy input to 0 if the value is not blank", ->
            destroys[0].val("1")
            values[0].val("1")
            values[0].trigger("change")
            expect(destroys[0]).toHaveValue("0")

        it "sets the destroy input to 0 if absent is checked", ->
            destroys[0].val("1")
            absents[0].attr("checked", "checked")
            values[0].trigger("change")
            expect(destroys[0]).toHaveValue("0")

    describe "disabled toggling", ->
        it "disables/enables the result entry when absent is checked/unchecked", ->
            absents[0].prop("checked", true).trigger("change")
            expect(values[0]).toBeDisabled()
            absents[0].prop("checked", false).trigger("change")
            expect(values[0]).not.toBeDisabled()

        it "only toggles when the absent checkbox is toggled", ->
            other = $('<input type="checkbox"/>')
            controls[0].append(other)
            other.prop("checked", true).trigger("change")
            expect(values[0]).not.toBeDisabled()
