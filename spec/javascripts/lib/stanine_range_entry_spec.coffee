describe "Digilys.StanineRangeEntry", ->
    form     = null
    max      = null
    minimums = null
    maximums = null
    entry    = null

    beforeEach ->
        form = $("<form>")
        max = $("<input/>")

        minimums = []
        maximums = []

        for i in [1..3]
            mn = $('<input class="stanine-field-min"/>')
            mx = $("<input class='stanine-field-max' data-stanine='#{i}'/>")

            d  = $("<div/>")

            d.append(mn).append(mx)
            form.append(d)

            minimums.push(form.find(".stanine-field-min:last"))
            maximums.push(form.find(".stanine-field-max:last"))

        entry = new Digilys.StanineRangeEntry
            form: form
            min: ".stanine-field-min"
            max: ".stanine-field-max"


    describe "constructor", ->

        it "stores a reference to all options", ->
            expect(entry.form).toEqual form
            expect(entry.min).toEqual  ".stanine-field-min"
            expect(entry.max).toEqual  ".stanine-field-max"

        it "binds a change listener to the form, filtered by the stanine max selector", ->
            spyOn(entry, "update")

            minimums[0].trigger("change")
            maximums[0].trigger("change")

            expect(entry.update.calls.count()).toEqual 1


    describe ".update()", ->

        it "infers the lower value for the entered ranges", ->
            maximums[0].val("5")
            maximums[1].val("10")
            maximums[2].val("15")

            entry.update()

            expect(minimums[0].val()).toEqual "0"
            expect(minimums[1].val()).toEqual "6"
            expect(minimums[2].val()).toEqual "11"

        it "infers the lower value from the previous complete range", ->
            maximums[0].val("5")
            maximums[1].val("")
            maximums[2].val("15")

            entry.update()

            expect(minimums[0].val()).toEqual "0"
            expect(minimums[1].val()).toEqual ""
            expect(minimums[2].val()).toEqual "6"

        it "sets the lower value to 0 if the range is the lowest complete range", ->
            maximums[0].val("")
            maximums[1].val("")
            maximums[2].val("15")

            entry.update()

            expect(minimums[0].val()).toEqual ""
            expect(minimums[1].val()).toEqual ""
            expect(minimums[2].val()).toEqual "0"

        it "clears the range if the value can't be parsed to an integer", ->
            maximums[0].val("zomg")
            maximums[1].val("lol")

            entry.update()

            expect(minimums[0].val()).toEqual ""
            expect(minimums[1].val()).toEqual ""

        it "support single value ranges", ->
            maximums[0].val("0")
            maximums[1].val("1")
            maximums[2].val("1")

            entry.update()

            expect(minimums[0].val()).toEqual "0"
            expect(minimums[1].val()).toEqual "1"
            expect(minimums[2].val()).toEqual "1"
