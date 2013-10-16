describe "Digilys.TagField", ->
    elem     = null
    tagField = null

    setup = (tags = null) ->
        elem = $('<input type="hidden" />')
        elem.attr("data-existing-tags", JSON.stringify(tags)) if tags

        tagField = new Digilys.TagField(elem)

    it "initializes a select2 field", ->
        setup()
        expect(elem).toHaveData("select2")

    it "supplies an empty array as the tag list by default", ->
        setup()
        expect(elem.data("select2").opts.tags).toEqual []

    it "supplies tags from the attribute data-existing-tags", ->
        setup(["foo", "bar"])
        expect(elem.data("select2").opts.tags).toEqual ["foo", "bar"]

    it "opens the select2 if the attribute data-autofocus exists", ->
        select2Opened = false

        elem = $('<input type="hidden" data-autofocus="true" />')
        elem.on "select2-opening", -> select2Opened = true

        # select2 throws exceptions when the element is detached from the DOM
        try
            new Digilys.TagField(elem)
        catch error

        expect(select2Opened).toBe true
