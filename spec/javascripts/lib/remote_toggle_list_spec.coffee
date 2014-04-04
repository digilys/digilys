describe "Digilys.RemoteToggleList", ->
    list       = null
    elem       = null
    checkboxes = null

    beforeEach ->
        elem       = $("<div data-on-url='on_url' data-off-url='off_url'/>")
        checkboxes = []

        for i in [1..3]
            checkbox = $("<input type=\"checkbox\" value=\"#{i}\"/>")
            elem.append(checkbox)
            checkboxes.push(checkbox)

        list = new Digilys.RemoteToggleList(elem, "my_param")


    describe "constructor", ->
        it "stores a reference to the list and the param name", ->
            expect(list.list).toEqual elem
            expect(list.param).toEqual "my_param"

        it "binds a change listener to the list, filtered by check boxes", ->
            spyOn(list, "update")

            checkboxes[0].trigger("change")

            input = $("<input/>")
            elem.append(input)
            input.trigger("change")

            expect(list.update.calls.count()).toEqual 1


    describe ".change()", ->
        url    = null
        params = null

        beforeEach ->
            spyOn($, "post").and.callFake (u, p) ->
                url    = u
                params = p
                return true

        it "performs an ajax request with the value of the checkbox in the param name", ->
            checkbox = checkboxes[1]
            checkbox.trigger("change")

            expect(params["my_param"]).toEqual [checkbox.val()]

        it "PUTs to the list's data-on-url attribute as url for checked boxes", ->
            checkbox = checkboxes[1]
            checkbox.attr("checked", "checked")
            checkbox.trigger("change")

            expect(url).toEqual           "on_url"
            expect(params._method).toEqual "put"

        it "DELETEs to the list's data-on-url attribute as url for unchecked boxes", ->
            checkbox = checkboxes[1]
            checkbox.removeAttr("checked")
            checkbox.trigger("change")

            expect(url).toEqual           "off_url"
            expect(params._method).toEqual "delete"
