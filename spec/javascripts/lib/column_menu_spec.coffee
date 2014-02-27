describe "Digilys.ColumnMenu", ->
    dataTable   = null
    columnIndex = null
    menuElem    = null
    onAction    = null
    columnMenu  = null

    beforeEach ->
        dataTable   = { fnSetColumnVis: -> }
        columnIndex = 3
        menuElem    = $("<div/>")
            .hide()
            .text("zomglol")
            .attr("id", "zomglol")

        onAction = ->

        columnMenu = new Digilys.ColumnMenu(dataTable, columnIndex, menuElem, onAction)

    describe "constructor", ->
        it "correctly assigns the arguments", ->
            expect(columnMenu.dataTable).toBe dataTable
            expect(columnMenu.columnIndex).toBe columnIndex
            expect(columnMenu.onAction).toBe onAction

        it "clones the menu, shows it, and removes the id", ->
            menu = columnMenu.menu

            expect(menu.get(0)).not.toBe menuElem.get(0)
            expect(menu).toHaveCss(display: "block")
            expect(menu).not.toHaveId("zomglol")

    describe ".handleAction()", ->
        it "is bound to the click event of data-action elements in the menu", ->
            trigger = $("<a/>").attr("data-action", "custom-action")
            columnMenu.menu.append(trigger)

            spyOn(columnMenu, "handleAction")
            spyOnEvent(trigger, "click")

            trigger.trigger("click")

            expect(columnMenu.handleAction).toHaveBeenCalledWith("custom-action")
            expect(columnMenu.handleAction).toHaveBeenCalledWith("custom-action")
            expect("click").toHaveBeenPreventedOn(trigger)

        it "calls .hide() when receiving the event hide-column", ->
            spyOn(columnMenu, "hide")
            columnMenu.handleAction("hide-column")
            expect(columnMenu.hide).toHaveBeenCalled()

        it "calls the onAction callback", ->
            spyOn(columnMenu, "onAction")
            columnMenu.handleAction("hide-column")
            expect(columnMenu.onAction).toHaveBeenCalled()

    describe ".hide()", ->
        it "hides the column with the correct index", ->
            spyOn(dataTable, "fnSetColumnVis")
            columnMenu.hide()
            expect(dataTable.fnSetColumnVis).toHaveBeenCalledWith(columnIndex, false)

