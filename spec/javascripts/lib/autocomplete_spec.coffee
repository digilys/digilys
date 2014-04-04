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
            expect(autocomplete.parseResults.calls.mostRecent().object).toBe(autocomplete)

        it "returns an object with two values parsed from the result", ->
            input =
                results: "foo"
                more:    "bar"
                dummy:   "zomg"

            expect(autocomplete.parseResults(input, 1)).toEqual
                results: "foo"
                more:    "bar"

    describe ".formatResult()", ->
        beforeEach ->
            setup()

        it "is called as the result formatting function of select2", ->
            spyOn(autocomplete, "formatResult")
            select2.opts.formatResult(1,2,3)
            expect(autocomplete.formatResult).toHaveBeenCalledWith(1,2,3)
            expect(autocomplete.formatResult.calls.mostRecent().object).toBe(autocomplete)

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
            expect(autocomplete.requestData.calls.mostRecent().object).toBe(autocomplete)

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


    describe ".enableAutosubmit()", ->
        beforeEach ->
            setup()
            autocomplete.enableAutosubmit("form")

        it "binds the change event of the field to autosubmit()", ->
            spyOn(autocomplete, "autosubmit")
            elem.trigger("change")
            expect(autocomplete.autosubmit).toHaveBeenCalled()

        it "stores the selector which should be masked", ->
            expect(autocomplete.maskSelector).toEqual "form"

        it "disables navigation confirmation on the parent form", ->
            expect(elem).toHaveData("preventNavigationConfirmation")


    describe ".autosubmit()", ->
        elem   = null
        submit = null
        form   = null

        beforeEach ->
            elem   = $('<input type = "hidden"/>')
            submit = $('<input type = "submit" data-loading-text="loading..."/>')
            form   = $('<form/>')

            form.append(elem).append(submit)

            autocomplete = new Digilys.Autocomplete(elem)

        it "submits the parent form", ->
            spy = jasmine.createSpy()
            form.on "submit", spy
            autocomplete.autosubmit()
            expect(spy).toHaveBeenCalled()

        it "disables any submit button in the parent form", ->
            autocomplete.autosubmit()
            expect(submit).toBeDisabled()

        it "switches the text of submit buttons with a loading text", ->
            autocomplete.autosubmit()
            expect(submit).toHaveValue("loading...")

        it "masks the elements specified by the mask selector", ->
            target = $("<div/>")
            autocomplete.enableAutosubmit(target)
            autocomplete.autosubmit()
            expect(target).toContainElement(".load-mask")


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


describe "Digilys.EvaluationAutocomplete", ->
    elem         = null
    autocomplete = null

    beforeEach ->
        elem         = $('<input type="hidden" />')
        autocomplete = new Digilys.EvaluationAutocomplete(elem)

    describe ".requestData()", ->
        it "uses name_or_suite_name_cont when a single search term is given", ->
            result = autocomplete.requestData("term", "page")
            expect(result.q).toEqual name_or_suite_name_cont: "term"

        it "uses both name_cont_any and suite_name_cont_any when multiple search terms are given", ->
            result = autocomplete.requestData("term1,term2", "page")
            expect(result.q).toEqual(
                name_cont_any: "term1,term2"
                suite_name_cont_any: "term1,term2"
            )

        it "removes any empty comma signs at the start and end of the term", ->
            result = autocomplete.requestData(" ,, ,term, ,", "page")
            expect(result.q).toEqual name_or_suite_name_cont: "term"


describe "Digilys.AuthorizationAutocomplete", ->
    elem         = null
    autocomplete = null
    list         = null

    beforeEach ->
        elem = $('<input type="hidden"/>').attr("data-base-url", "/foo/bar")
        list = $("<div/>")

        elem.data("list", list.get(0))

        autocomplete = new Digilys.AuthorizationAutocomplete(elem)
        jasmine.Ajax.install()

    afterEach ->
        jasmine.Ajax.uninstall()

    describe ".constructor", ->
        it "stores the base url from the element", ->
            expect(autocomplete.url).toEqual("/foo/bar")

        it "stores a jQuery reference to the list referenced by data-list", ->
            expect(autocomplete.list.get(0)).toEqual(list.get(0))

    describe ".select()", ->
        beforeEach ->
            elem.val("123")

        it "is bound to the change event on the element", ->
            spyOn(autocomplete, "select")
            elem.trigger("change")
            expect(autocomplete.select).toHaveBeenCalled()
            expect(autocomplete.select.calls.mostRecent().object).toBe(autocomplete)

        it "clears the select2 element", ->
            spyOn(elem.data("select2"), "clear")
            autocomplete.select()
            expect(elem.data("select2").clear).toHaveBeenCalled()

        it "calls the base url with the selection", ->
            autocomplete.select()

            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toEqual    "/foo/bar"
            expect(request.method).toEqual "POST"
            expect(request.params).toMatch "user_id=123"
            expect(request.params).toMatch "roles=reader"

        it "does nothing if the select was not a valid id", ->
            elem.val("")
            spyOn(elem.data("select2"), "clear")
            autocomplete.select()
            expect(elem.data("select2").clear).not.toHaveBeenCalled()

    describe ".added()", ->
        beforeEach ->
            elem.val("123")

        it "is called if the select request was successful", ->
            spyOn(autocomplete, "added")

            autocomplete.select()

            request = jasmine.Ajax.requests.mostRecent()
            request.response(status: 200, responseText: '{"foo":"bar"}')

            expect(autocomplete.added).toHaveBeenCalledWith(foo: "bar")
            expect(autocomplete.added.calls.mostRecent().object).toBe(autocomplete)

        it "triggers an authorization-added event on the list", ->
            spy = jasmine.createSpy()
            list.on "authorization-added", spy
            autocomplete.added(foo: "bar")

            expect(spy).toHaveBeenCalledWith(jasmine.any(Object), { foo: "bar" })
