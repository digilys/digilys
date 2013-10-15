describe "Digilys.LoadMask", ->
    elem     = null
    loadMask = null

    beforeEach ->
        elem     = $("<div/>")
        loadMask = new Digilys.LoadMask(elem)

    it "sets the element's position to relative", ->
        expect(elem).toHaveCss position: "relative"

    it "adds a load mask element to the element", ->
        expect(elem).toContain ".load-mask"

    it "adds the loadmask instance as a data value to the element", ->
        expect(elem).toHaveData "LoadMask", loadMask

    describe ".disable()", ->
        beforeEach ->
            loadMask.disable()

        it "removes the load mask", ->
            expect(elem).not.toContain ".load-mask"
