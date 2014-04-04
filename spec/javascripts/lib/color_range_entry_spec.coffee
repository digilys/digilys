describe "Digilys.ColorRangeEntry", ->
    entry  = null
    fields = null

    generateFields = ->
        max:         $("<input/>")
        red:
            min:     $("<input/>")
            max:     $("<input/>")
        yellow:
            min:     $("<input/>")
            max:     $("<input/>")
        green:
            min:     $("<input/>")
            max:     $("<input/>")
        text:
            red:
                min: $("<input/>")
                max: $("<input/>")
            yellow:
                min: $("<input/>")
                max: $("<input/>")
            green:
                min: $("<input/>")
                max: $("<input/>")


    beforeEach ->
        fields = generateFields()
        entry = new Digilys.ColorRangeEntry(fields)


    describe "constructor", ->

        it "stores a reference to all fields", ->
            expect(entry.fields.max).toEqual             fields.max
            expect(entry.fields.red.min).toEqual         fields.red.min
            expect(entry.fields.red.max).toEqual         fields.red.max
            expect(entry.fields.yellow.min).toEqual      fields.yellow.min
            expect(entry.fields.yellow.max).toEqual      fields.yellow.max
            expect(entry.fields.green.min).toEqual       fields.green.min
            expect(entry.fields.green.max).toEqual       fields.green.max
            expect(entry.fields.text.red.min).toEqual    fields.text.red.min
            expect(entry.fields.text.red.max).toEqual    fields.text.red.max
            expect(entry.fields.text.yellow.min).toEqual fields.text.yellow.min
            expect(entry.fields.text.yellow.max).toEqual fields.text.yellow.max
            expect(entry.fields.text.green.min).toEqual  fields.text.green.min
            expect(entry.fields.text.green.max).toEqual  fields.text.green.max

        it "flips the values of the text displays if there's a previous reversed range", ->
            fields.max.val             "50"

            fields.red.min.val         "31"
            fields.red.max.val         "50"
            fields.yellow.min.val      "20"
            fields.yellow.max.val      "30"
            fields.green.min.val       "0"
            fields.green.max.val       "19"

            fields.text.red.min.val    "31"
            fields.text.red.max.val    "50"
            fields.text.yellow.min.val "20"
            fields.text.yellow.max.val "30"
            fields.text.green.min.val  "0"
            fields.text.green.max.val  "19"
            
            entry = new Digilys.ColorRangeEntry(fields)

            expect(fields.text.red.min.val()).toEqual    "50"
            expect(fields.text.red.max.val()).toEqual    "31"
            expect(fields.text.yellow.min.val()).toEqual "30"
            expect(fields.text.yellow.max.val()).toEqual "20"
            expect(fields.text.green.min.val()).toEqual  "19"
            expect(fields.text.green.max.val()).toEqual  "0"

    describe ".update()", ->
        it "is called when the max and the yellow text field change", ->
            spyOn(entry, "update")
            
            fields.max.trigger("change")
            fields.text.yellow.min.trigger("change")
            fields.text.yellow.max.trigger("change")

            expect(entry.update.calls.count()).toEqual(3)
            expect(entry.update.calls.mostRecent().object).toBe(entry)

        describe "text fields", ->
            setValues = (max, yellowMin, yellowMax) ->
                fields.max.val(max)                   if max isnt null
                fields.text.yellow.min.val(yellowMin) if yellowMin isnt null
                fields.text.yellow.max.val(yellowMax) if yellowMax isnt null

                entry.update()

            it "updates the text fields", ->
                setValues("50", "25", "40")

                expect(fields.text.red.min.val()).toEqual   "0"
                expect(fields.text.red.max.val()).toEqual   "24"

                expect(fields.text.green.min.val()).toEqual "41"
                expect(fields.text.green.max.val()).toEqual "50"

            it "reverses the text display when the range is entered in reverse order", ->
                setValues("50", "40", "25")

                expect(fields.text.red.min.val()).toEqual   "50"
                expect(fields.text.red.max.val()).toEqual   "41"

                expect(fields.text.green.min.val()).toEqual "24"
                expect(fields.text.green.max.val()).toEqual "0"

            it "clears the values if there is no maximum value", ->
                # Start with something so there are values set
                setValues("50", "25", "40")
                setValues("", "25", "40")

                expect(fields.text.red.min.val()).toEqual   ""
                expect(fields.text.red.max.val()).toEqual   ""
                expect(fields.text.green.min.val()).toEqual ""
                expect(fields.text.green.max.val()).toEqual ""

                # reverse
                setValues("", "40", "25")

                expect(fields.text.red.min.val()).toEqual   ""
                expect(fields.text.red.max.val()).toEqual   ""
                expect(fields.text.green.min.val()).toEqual ""
                expect(fields.text.green.max.val()).toEqual ""

            it "clears the values if the range is not complete", ->
                # Start with something so there are values set
                setValues("50", "25", "40")
                setValues("50", "", "40")

                expect(fields.text.red.min.val()).toEqual   ""
                expect(fields.text.red.max.val()).toEqual   ""
                expect(fields.text.green.min.val()).toEqual ""
                expect(fields.text.green.max.val()).toEqual ""

                setValues("50", "40", "")

                expect(fields.text.red.min.val()).toEqual   ""
                expect(fields.text.red.max.val()).toEqual   ""
                expect(fields.text.green.min.val()).toEqual ""
                expect(fields.text.green.max.val()).toEqual ""

            it "clears the lower range if the range min is 0", ->
                setValues("50", "0", "40")
                expect(fields.text.red.min.val()).toEqual   ""
                expect(fields.text.red.max.val()).toEqual   ""

                setValues("50", "40", "0")
                expect(fields.text.green.min.val()).toEqual ""
                expect(fields.text.green.max.val()).toEqual ""

            it "clears the upper range if the range max is the same as the max", ->
                setValues("50", "25", "50")
                expect(fields.text.green.min.val()).toEqual ""
                expect(fields.text.green.max.val()).toEqual ""

                setValues("50", "50", "25")
                expect(fields.text.red.min.val()).toEqual   ""
                expect(fields.text.red.max.val()).toEqual   ""

            it "interprets a single value range as regular order", ->
                setValues("50", "25", "25")

                expect(fields.text.red.min.val()).toEqual   "0"
                expect(fields.text.red.max.val()).toEqual   "24"

                expect(fields.text.green.min.val()).toEqual "26"
                expect(fields.text.green.max.val()).toEqual "50"

            it "supports percentages", ->
                setValues("50", "30%", "60%")

                expect(fields.text.red.min.val()).toEqual   "0%"
                expect(fields.text.red.max.val()).toEqual   "29%"

                expect(fields.text.green.min.val()).toEqual "61%"
                expect(fields.text.green.max.val()).toEqual "100%"

                setValues("50", "60%", "30%")

                expect(fields.text.red.min.val()).toEqual   "100%"
                expect(fields.text.red.max.val()).toEqual   "61%"

                expect(fields.text.green.min.val()).toEqual "29%"
                expect(fields.text.green.max.val()).toEqual "0%"

            it "defaults to percentages if the first value in the range is a percentage", ->
                setValues("50", "30%", "60")
                expect(fields.text.red.min.val()).toEqual   "0%"
                setValues("50", "60%", "30")
                expect(fields.text.green.max.val()).toEqual   "0%"
                setValues("50", "30", "60%")
                expect(fields.text.red.min.val()).toEqual   "0"
                setValues("50", "60", "30%")
                expect(fields.text.green.max.val()).toEqual   "0"

        describe "value fields", ->
            setValues = (max, yellowMin, yellowMax) ->
                fields.max.val(max)                   if max isnt null
                fields.text.yellow.min.val(yellowMin) if yellowMin isnt null
                fields.text.yellow.max.val(yellowMax) if yellowMax isnt null

                entry.update()

            it "updates the value fields", ->
                setValues("50", "25", "40")

                expect(fields.red.min.val()).toEqual    "0"
                expect(fields.red.max.val()).toEqual    "24"

                expect(fields.yellow.min.val()).toEqual "25"
                expect(fields.yellow.max.val()).toEqual "40"

                expect(fields.green.min.val()).toEqual  "41"
                expect(fields.green.max.val()).toEqual  "50"

            it "supports reversed order when the input range is reversed", ->
                setValues("50", "40", "25")

                expect(fields.red.min.val()).toEqual    "41"
                expect(fields.red.max.val()).toEqual    "50"

                expect(fields.yellow.min.val()).toEqual "25"
                expect(fields.yellow.max.val()).toEqual "40"

                expect(fields.green.min.val()).toEqual  "0"
                expect(fields.green.max.val()).toEqual  "24"

            it "clears the values if there is no maximum value", ->
                # Start with something so there are values set
                setValues("50", "25", "40")
                setValues("", "25", "40")

                expect(fields.red.min.val()).toEqual    ""
                expect(fields.red.max.val()).toEqual    ""
                expect(fields.yellow.min.val()).toEqual ""
                expect(fields.yellow.max.val()).toEqual ""
                expect(fields.green.min.val()).toEqual  ""
                expect(fields.green.max.val()).toEqual  ""

                # reverse
                setValues("", "40", "25")

                expect(fields.red.min.val()).toEqual    ""
                expect(fields.red.max.val()).toEqual    ""
                expect(fields.yellow.min.val()).toEqual ""
                expect(fields.yellow.max.val()).toEqual ""
                expect(fields.green.min.val()).toEqual  ""
                expect(fields.green.max.val()).toEqual  ""

            it "clears the values if the range is not complete", ->
                # Start with something so there are values set
                setValues("50", "25", "40")
                setValues("50", "", "40")

                expect(fields.red.min.val()).toEqual    ""
                expect(fields.red.max.val()).toEqual    ""
                expect(fields.yellow.min.val()).toEqual ""
                expect(fields.yellow.max.val()).toEqual ""
                expect(fields.green.min.val()).toEqual  ""
                expect(fields.green.max.val()).toEqual  ""

                setValues("50", "40", "")

                expect(fields.red.min.val()).toEqual    ""
                expect(fields.red.max.val()).toEqual    ""
                expect(fields.yellow.min.val()).toEqual ""
                expect(fields.yellow.max.val()).toEqual ""
                expect(fields.green.min.val()).toEqual  ""
                expect(fields.green.max.val()).toEqual  ""

            it "clears the lower range if the range min is 0", ->
                setValues("50", "0", "40")
                expect(fields.red.min.val()).toEqual   ""
                expect(fields.red.max.val()).toEqual   ""

                setValues("50", "40", "0")
                expect(fields.green.min.val()).toEqual ""
                expect(fields.green.max.val()).toEqual ""

            it "clears the upper range if the range max is the same as the max", ->
                setValues("50", "25", "50")
                expect(fields.green.min.val()).toEqual ""
                expect(fields.green.max.val()).toEqual ""

                setValues("50", "50", "25")
                expect(fields.red.min.val()).toEqual   ""
                expect(fields.red.max.val()).toEqual   ""

            it "interprets a single value range as regular order", ->
                setValues("50", "25", "25")

                expect(fields.red.min.val()).toEqual    "0"
                expect(fields.red.max.val()).toEqual    "24"

                expect(fields.yellow.min.val()).toEqual "25"
                expect(fields.yellow.max.val()).toEqual "25"

                expect(fields.green.min.val()).toEqual  "26"
                expect(fields.green.max.val()).toEqual  "50"

            it "calculates the real values if the range is a percentage range", ->
                setValues("50", "25%", "50%")

                expect(fields.red.min.val()).toEqual    "0"
                expect(fields.red.max.val()).toEqual    "11.5"

                expect(fields.yellow.min.val()).toEqual "12.5"
                expect(fields.yellow.max.val()).toEqual "25"

                expect(fields.green.min.val()).toEqual  "26"
                expect(fields.green.max.val()).toEqual  "50"

                # reverse
                setValues("50", "50%", "25%")

                expect(fields.red.min.val()).toEqual    "26"
                expect(fields.red.max.val()).toEqual    "50"

                expect(fields.yellow.min.val()).toEqual "12.5"
                expect(fields.yellow.max.val()).toEqual "25"

                expect(fields.green.min.val()).toEqual  "0"
                expect(fields.green.max.val()).toEqual  "11.5"


    describe ".addSuffix()", ->
        it "adds a suffix to a string", ->
            expect(entry.addSuffix("foo", "bar")).toEqual "foobar"

        it "adds converts the value to a string", ->
            expect(entry.addSuffix(1, "bar")).toEqual "1bar"

        it "returns an empty string if the value is null", ->
            expect(entry.addSuffix(null, "bar")).toEqual ""
