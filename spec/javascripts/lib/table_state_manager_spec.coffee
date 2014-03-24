describe "Digilys.TableStateManager", ->
    list       = null
    selector   = null
    name       = null
    saveButton = null
    manager    = null

    beforeEach ->
        selector = $("<select/>")
            .attr("data-url", "select/:id")
            .attr("data-clear-url", "clear-state")

        selector.append($("<option>Default</option>"))
        selector.append($("<option value=\"0\">Clear</option>"))
        selector.append($("<option value=\"1\">Existing #1</option>"))

        list = $("<table/>")
            .attr("data-delete-action-name", "delete-action")

        $("<tr/>")
            .attr("data-id", "1")
            .append("<td/>")
            .append("<td/>")
            .appendTo(list)

        name = $("<input/>")

        saveButton = $("<button/>")
            .addClass("btn")
            .data("url", "save-url")
            .data("datatable", $("<div/>").data("color-table", { getState: -> {current: "state"} }))

        manager = new Digilys.TableStateManager(list, selector, name, saveButton)

        spyOn(manager, "redirect")
        spyOn($.rails, "handleMethod")

        jasmine.Ajax.install()
        jasmine.clock().install()

    afterEach ->
        jasmine.Ajax.uninstall()
        jasmine.clock().uninstall()

    describe "selecting", ->
        it "redirects to the page for selecting a table state", ->
            selector.val("1")
            selector.trigger("change")

            expect(selector).toBeDisabled()
            expect(manager.redirect).toHaveBeenCalledWith("select/1")

        it "performs a delete request using rails.js when selecting to reset the table state", ->
            selector.val("0")
            selector.trigger("change")

            expect(selector).toBeDisabled()
            expect($.rails.handleMethod).toHaveBeenCalled()

        it "does not request anything if selecting the default value", ->
            selector.val("")
            selector.trigger("change")

            expect(selector).not.toBeDisabled()
            expect(manager.redirect).not.toHaveBeenCalled()
            expect($.rails.handleMethod).not.toHaveBeenCalled()

    describe "saving", ->
        it "posts the table state to the backend", ->
            name.val("name")
            saveButton.trigger("click")

            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toEqual    "save-url"
            expect(request.method).toEqual "POST"
            expect(request.params).toMatch "table_state%5Bname%5D=name"
            expect(request.params).toMatch "table_state%5Bdata%5D=%7B%22current%22%3A%22state%22%7D"

        it "does not save states without a name", ->
            name.val("")
            saveButton.trigger("click")
            request = jasmine.Ajax.requests.mostRecent()
            expect(request).toBeUndefined()

        it "masks the save button during the request", ->
            name.val("name")
            saveButton.trigger("click")

            # required since bootstrap-button pushes the disabled state setting
            # to the event loop
            jasmine.clock().tick(1)

            expect(saveButton).toBeDisabled()

            request = jasmine.Ajax.requests.mostRecent()
            request.response(
                status: 200
                responseText: '{"id":2,"name":"name","urls":{"default":"default-url","select":"select-url"}}'
            )

            jasmine.clock().tick(1)

            expect(saveButton).not.toBeDisabled()

        it "clears the name input", ->
            name.val("name")
            saveButton.trigger("click")
            request = jasmine.Ajax.requests.mostRecent()
            request.response(
                status: 200
                responseText: '{"id":2,"name":"name","urls":{"default":"default-url","select":"select-url"}}'
            )
            expect(name).toHaveValue("")

        describe "new states", ->
            beforeEach ->
                name.val("name")
                saveButton.trigger("click")

                request = jasmine.Ajax.requests.mostRecent()
                request.response(
                    status: 200
                    responseText: '{"id":2,"name":"name","urls":{"default":"default-url","select":"select-url"}}'
                )

            it "adds new saved states to the list", ->
                cells = list.find("[data-id=2]").children()

                link = $(cells[0]).find("a")

                expect(link).toHaveText("name")
                expect(link).toHaveAttr("href", "select-url")

                link = $(cells[1]).find("a")

                expect(link).toHaveText("delete-action")
                expect(link).toHaveAttr("href", "default-url")
                expect(link).toHaveAttr("data-method", "delete")
                expect(link).toHaveAttr("data-remote", "true")

            it "adds new saved states to the selector", ->
                expect(selector.find("[value=2]")).toHaveText("name")

        describe "existing states", ->
            beforeEach ->
                name.val("name")
                saveButton.trigger("click")

                request = jasmine.Ajax.requests.mostRecent()
                request.response(status: 200, responseText: '{"id":1,"name":"name"}')

            it "does not add updated states to the list", ->
                expect(list.find("[data-id=1]")).toHaveLength(1)

            it "does not add updated states to the selector", ->
                expect(selector.find("[value=1]")).toHaveLength(1)

    describe "deleting", ->
        beforeEach ->
            list.find("[data-id=1] :first-child").trigger("ajax:success", {id: 1})

        it "removes the state from the list", ->
            expect(list.find("[data-id=1]")).toHaveLength(0)

        it "removes the state from the selector", ->
            expect(selector.find("[value=1]")).toHaveLength(0)
