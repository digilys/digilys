describe "Digilys.LazyDropdown", ->
    elem     = null
    menu     = null
    wrapper  = null
    dropdown = null

    beforeEach ->
        spyOn($, "ajax").andCallFake (options) ->
            options.success("menu-content", "textStatus", {})

        elem     = $('<a href="#"/>')
        menu     = $('<div class="dropdown-menu"><div class="load-indicator"></div></div>')
        wrapper  = $("<div/>").append(elem).append(menu)
        dropdown = new Digilys.LazyDropdown(elem)

    it "triggers the loading on click, once", ->
        spyOn(dropdown, "loadDropdown")
        dropdown.toggler.trigger("click")
        dropdown.toggler.trigger("click")

        expect(dropdown.loadDropdown).toHaveBeenCalled()
        expect(dropdown.loadDropdown.calls.length).toEqual 1

    describe "loadMenu()", ->
        it "loads the menu content from the trigger's address via ajax", ->
            spyOn(dropdown, "setMenu")
            dropdown.loadDropdown()

            expect($.ajax).toHaveBeenCalled()
            expect(dropdown.setMenu).toHaveBeenCalledWith("menu-content")

    describe "setMenu()", ->
        it "replaces the load indicator in the dropdown menu by the given content", ->
            dropdown.setMenu("zomglol")
            expect(menu).not.toContain(".load-indicator")
            expect(menu.html()).toEqual "zomglol"
