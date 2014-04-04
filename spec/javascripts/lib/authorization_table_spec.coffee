describe "Digilys.AuthorizationTable", ->
    table        = null
    elem         = null
    container    = null
    removeButton = null
    editorToggle = null

    beforeEach ->
        elem         = $("<table/>").data("base-url", "/foo/bar")
        tbody        = $("<tbody/>").appendTo(elem)
        container    = $("<tr/>").attr("data-id", "123").appendTo(tbody)
        removeButton = $("<button/>").addClass("remove-action").appendTo(container)
        editorToggle = $('<input type="checkbox"/>').appendTo(container)

        table = new Digilys.AuthorizationTable(elem)

        jasmine.Ajax.install()

    afterEach ->
        jasmine.Ajax.uninstall()

    describe "constructor", ->
        it "correctly assigns the arguments", ->
            expect(table.elem).toBe elem

        it "stores the base url from the element", ->
            expect(table.url).toEqual = "/foo/bar"

    describe ".remove()", ->
        it "is bound to click events on .remove-action buttons", ->
            cnt = null
            self = null
            table.remove = (c) ->
                cnt = c
                self = this
            removeButton.trigger("click")
            expect(cnt.get(0)).toBe container.get(0)
            expect(self).toBe table

        it "posts a delete request to the base url", ->
            table.remove(container)

            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toEqual    "/foo/bar"
            expect(request.method).toEqual "POST"
            expect(request.params).toMatch "user_id=123"
            expect(request.params).toMatch "roles=reader%2Ceditor"
            expect(request.params).toMatch "_method=delete"

    describe ".removed()", ->
        it "is called if the remove action was successful", ->
            spyOn(table, "removed")

            table.remove(container)

            request = jasmine.Ajax.requests.mostRecent()
            request.response(status: 200, responseText: "{}")

            expect(table.removed).toHaveBeenCalledWith(container)
            expect(table.removed).toHaveBeenCalledOn(table)

        it "removes the specified row", ->
            table.removed(container)
            expect(elem).not.toContainElement("[data-id=123]")

    describe ".added()", ->
        it "is called when an authorization-added event is triggered on the element", ->
            spyOn(table, "added")
            elem.trigger("authorization-added", {foo: "bar"})
            expect(table.added).toHaveBeenCalledWith(foo: "bar")
            expect(table.added).toHaveBeenCalledOn(table)

        it "adds the userData row to the table", ->
            table.added(row: '<tr class="user-data-row"></tr>')
            expect(elem).toContainElement("tbody .user-data-row")

        it "does not add duplicate rows, based on data-id", ->
            table.added(id: "124", row: '<tr data-id="124" class="user-data-row"></tr>')
            table.added(id: "124", row: '<tr data-id="124" class="user-data-row"></tr>')
            expect(elem.find("tbody .user-data-row")).toHaveLength(1)

    describe ".toggleEditor()", ->
        it "is called when a checkbox is changed", ->
            spyOn(table, "toggleEditor")
            editorToggle.trigger("change")
            expect(table.toggleEditor.calls.mostRecent().args[0][0]).toEqual(editorToggle[0])
            expect(table.toggleEditor).toHaveBeenCalledOn(table)

        it "posts a create request to the base url when the checkbox is checked", ->
            editorToggle.attr("checked", "checked")
            table.toggleEditor(editorToggle)

            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toEqual    "/foo/bar"
            expect(request.method).toEqual "POST"
            expect(request.params).toMatch "user_id=123"
            expect(request.params).toMatch "roles=editor"

        it "posts a delete request to the base url", ->
            editorToggle.removeAttr("checked")
            table.toggleEditor(editorToggle)

            request = jasmine.Ajax.requests.mostRecent()
            expect(request.url).toEqual    "/foo/bar"
            expect(request.method).toEqual "POST"
            expect(request.params).toMatch "user_id=123"
            expect(request.params).toMatch "roles=editor"
            expect(request.params).toMatch "_method=delete"

