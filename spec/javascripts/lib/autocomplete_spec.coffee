describe "Digilys.Autocomplete", ->
    elem         = null
    autocomplete = null
    select2      = null

    setup = (attributes = {}) ->
        elem = $('<input type="hidden" />')
        elem.attr(name, value) for name, value of attributes

        autocomplete = new Digilys.Autocomplete(elem)
        select2      = elem.data("select2")


    describe "select2 initialization", ->
        beforeEach ->
            setup
                "data-multiple": "true"
                "data-url":      "/my/url"

        it "initializes a select2 field", ->
            expect(elem).toHaveData "select2"

        it "sets basic options", ->
            expect(select2.opts.width).toBe("off")
            expect(select2.opts.minimumInputLength).toBe(0)

        it "loads options from data attributes", ->
            expect(select2.opts.multiple).toBe(true)
            expect(select2.opts.ajax.url).toBe("/my/url")

    describe "select2 data", ->
        beforeEach ->
            setup "data-data": JSON.stringify([ { id: 1, name: "foo" } ])

        it "sets select2 data from the attribute data-data", ->
            expect(elem.select2("data")).toEqual [ { id: 1, name: "foo" } ]


    describe "with multiple elements", ->
        it "sets up a select2 instance per element", ->
            elem1 = $('<input type="hidden" />')
            elem2 = $('<input type="hidden" />')
            elem1.attr("data-multiple", "true")

            autocomplete = new Digilys.Autocomplete(elem2.add(elem1))

            expect(elem1).toHaveData "select2"
            expect(elem2).toHaveData "select2"

            expect(elem1.data("select2").opts.multiple).toBe true
            expect(elem2.data("select2").opts.multiple).not.toBe true


    describe "select2 autofocus", ->
        it "opens the select2 if the attribute data-autofocus exists", ->
            select2Opened = false

            elem = $('<input type="hidden" data-autofocus="true" />')
            elem.on "select2-opening", -> select2Opened = true

            # select2 throws exceptions when the element is detached from the DOM
            try
                new Digilys.Autocomplete(elem)
            catch error

            expect(select2Opened).toBe true


    describe ".parseResults()", ->
        beforeEach ->
            setup()

        it "is called as the results parsing function of select2", ->
            spyOn(autocomplete, "parseResults")
            select2.opts.ajax.results({ results: "foo", more: "bar" }, 1)
            expect(autocomplete.parseResults).toHaveBeenCalledWith({ results: "foo", more: "bar" }, 1)

        it "returns an object with two values parsed from the result", ->
            input =
                results: "foo"
                more:    "bar"
                dummy:   "zomg"

            expect(autocomplete.parseResults(input, 1)).toEqual
                results: "foo"
                more:    "bar"

        it "is called with the right context", ->
            myThis = null
            autocomplete.parseResults = -> myThis = this
            select2.opts.ajax.results(1, 1)
            expect(myThis).toBe autocomplete

    describe ".formatResult()", ->
        beforeEach ->
            setup()

        it "is called as the result formatting function of select2", ->
            spyOn(autocomplete, "formatResult")
            select2.opts.formatResult(1,2,3)
            expect(autocomplete.formatResult).toHaveBeenCalledWith(1,2,3)

        it "is called with the right context", ->
            myThis = null
            autocomplete.formatResult = -> myThis = this
            select2.opts.formatResult(1,2,3)
            expect(myThis).toBe autocomplete

        it "defaults to select2's formatResult", ->
            expect(autocomplete.formatResult).toBe $.fn.select2.defaults.formatResult


    describe ".requestData()", ->
        beforeEach ->
            elem = $('<input type="hidden" />')

        it "is called as the data function for the select2 ajax request", ->
            autocomplete = new Digilys.Autocomplete(elem)
            spyOn(autocomplete, "requestData")
            elem.data("select2").opts.ajax.data(1,2,3)
            expect(autocomplete.requestData).toHaveBeenCalledWith(1,2,3)

        it "is called with the right context", ->
            autocomplete             = new Digilys.Autocomplete(elem)
            myThis                   = null
            autocomplete.requestData = -> myThis = this

            elem.data("select2").opts.ajax.data(1,2,3)
            expect(myThis).toBe autocomplete

        it "defaults to a query by name", ->
            autocomplete = new Digilys.Autocomplete(elem)
            result       = autocomplete.requestData("term", "page")

            expect(result.q).toEqual    name_cont: "term"
            expect(result.page).toEqual "page"

        it "is possible to change the query fields upon initialization", ->
            autocomplete = new Digilys.Autocomplete(elem, "foo_cont", "bar_cont")
            result       = autocomplete.requestData("term", "page")

            expect(result.q).toEqual    foo_cont: "term", bar_cont: "term"
            expect(result.page).toEqual "page"


describe "Digilys.DescriptionAutocomplete", ->
    elem         = null
    autocomplete = null

    beforeEach ->
        elem         = $('<input type="hidden" />')
        autocomplete = new Digilys.DescriptionAutocomplete(elem)

    describe ".requestData()", ->
        it "defaults to a query by name or description", ->
            result = autocomplete.requestData("term", "page")
            expect(result.q).toEqual    name_or_description_cont: "term"
            expect(result.page).toEqual "page"

    describe ".formatResult()", ->
        it "separates the name and description, wrapping the description in small tags", ->
            result = autocomplete.formatResult(
                { name: "name", description: "description" },
                null,
                { term: "zomg" },
                (str) -> str
            )
            expect(result).toEqual "name<small>description</small>"

        it "marks matches using the default select2 mark function", ->
            result = autocomplete.formatResult(
                { name: "foozomgbar", description: "barzomgbaz" },
                null,
                { term: "zomg" },
                (str) -> str
            )

            expect(result).toEqual "foo<span class='select2-match'>zomg</span>bar<small>bar<span class='select2-match'>zomg</span>baz</small>"

describe "Digilys.GroupAutocomplete", ->
    elem         = null
    autocomplete = null

    beforeEach ->
        elem         = $('<input type="hidden" />')
        autocomplete = new Digilys.GroupAutocomplete(elem)

    describe ".requestData()", ->
        it "generates a parent condition for every comma separated value in the term", ->
            result = autocomplete.requestData("term,foo,bar,baz", "page")

            expect(result.page).toEqual            "page"
            expect(result.q.name_cont).toEqual     "term"
            expect(result.q.parent_0_name_cont).toEqual "foo"
            expect(result.q.parent_1_name_cont).toEqual "bar"
            expect(result.q.parent_2_name_cont).toEqual "baz"


describe "Digilys.StudentGroupAutocomplete", ->
    elem         = null
    autocomplete = null

    beforeEach ->
        elem         = $('<input type="hidden" />')
        autocomplete = new Digilys.StudentGroupAutocomplete(elem)

    describe ".requestData()", ->
        it "generates a query for both students and groups", ->
            result = autocomplete.requestData("term", "page")
            expect(result.sq).toEqual   first_name_or_last_name_cont: "term"
            expect(result.gq).toEqual   name_cont:                    "term"
            expect(result.page).toEqual "page"
