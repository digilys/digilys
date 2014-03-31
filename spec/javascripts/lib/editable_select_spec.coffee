describe "Digilys.EditableSelect", ->
    elem        = null
    select      = null
    data        = [
        {id: 1, text: "foo"},
        {id: 2, text: "bar"}
    ]

    beforeEach ->
        elem = $('<input type="text"/>')
        elem.attr(
            "data-data",
            JSON.stringify(data)
        )
        elem.attr("data-placeholder", "my-placeholder")

        select = new Digilys.EditableSelect(elem)

    it "initializes a select2 field", ->
        expect(elem).toHaveData("select2")
        expect(elem.data("select2").opts.allowClear).toEqual true

    it "loads the placeholder for select2 from the data-placeholder attribute", ->
        expect(elem.data("select2").opts.placeholder).toEqual "my-placeholder"

    it "loads data for select2 from the data-data attribute", ->
        expect(elem.data("select2").opts.data).toEqual data

    describe ".buildChoice()", ->
        it "gets called as select2's createSearchChoice", ->
            spyOn(select, "buildChoice")
            elem.data("select2").opts.createSearchChoice("term", {})
            expect(select.buildChoice).toHaveBeenCalledWith "term", {}

        it "returns null if the term already exists in the data", ->
            result = select.buildChoice("term", { id: 1, text: "term" })
            expect(result).toBe null

        it "returns the term as both id and text", ->
            result = select.buildChoice("term", {})
            expect(result).toEqual { id: "term", text: "term" }

