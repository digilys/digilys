describe "Digilys.ColumnMenu", ->
    dataTable   = null
    columnIndex = null
    menuElem    = null
    showTrigger = null
    options     = null
    columnMenu  = null


    beforeEach ->
        dataTable =
            fnSetColumnVis: ->
            fnSettings: -> aoColumns: []

        columnIndex = 3
        menuElem    = $("<div/>")
            .hide()
            .text("zomglol")
            .attr("id", "zomglol")


        showTrigger  = $("<a/>").attr("data-action", "show-column")

        menuElem.append(showTrigger)

        options = {}

        columnMenu = new Digilys.ColumnMenu(dataTable, columnIndex, menuElem, options)


    describe "constructor", ->
        it "correctly assigns the arguments", ->
            expect(columnMenu.dataTable).toBe dataTable
            expect(columnMenu.columnIndex).toBe columnIndex
            expect(columnMenu.options).toBe options

        it "clones the menu, shows it, and removes the id", ->
            menu = columnMenu.menu

            expect(menu.get(0)).not.toBe menuElem.get(0)
            expect(menu).toHaveCss(display: "block")
            expect(menu).not.toHaveId("zomglol")

        it "removes the show-column action if there are no hidden columns", ->
            expect(columnMenu.menu.find("[data-action=show-column]")).toHaveLength(0)

        it "adds a locked class to the menu if options.locked is set", ->
            expect(columnMenu.menu).not.toHaveClass("locked")

            options.locked = true

            columnMenu = new Digilys.ColumnMenu(dataTable, columnIndex, menuElem, options)
            expect(columnMenu.menu).toHaveClass("locked")


    describe ".handleAction()", ->
        it "is bound to the click event of data-action elements in the menu", ->
            trigger = $("<a/>").attr("data-action", "custom-action")
            columnMenu.menu.append(trigger)

            spyOn(columnMenu, "handleAction")
            spyOnEvent(trigger, "click")

            trigger.trigger("click")

            expect(columnMenu.handleAction).toHaveBeenCalledWith("custom-action", trigger)
            expect("click").toHaveBeenPreventedOn(trigger)

        it "calls .hide() when receiving the event hide-column", ->
            spyOn(columnMenu, "hide")
            columnMenu.handleAction("hide-column")
            expect(columnMenu.hide).toHaveBeenCalled()

        it "calls .showModal() when receiving the event show-column", ->
            spyOn(columnMenu, "showModal")
            columnMenu.handleAction("show-column")
            expect(columnMenu.showModal).toHaveBeenCalled()

        it "calls the action callbacks", ->
            options.beforeAction = ->
            options.afterAction = ->

            spyOn(options, "beforeAction")
            spyOn(options, "afterAction")

            columnMenu.handleAction("hide-column")

            expect(options.beforeAction).toHaveBeenCalled()
            expect(options.afterAction).toHaveBeenCalled()

        it "calls .lock() when receiving the event lock-column", ->
            spyOn(columnMenu, "lock")
            columnMenu.handleAction("lock-column")
            expect(columnMenu.lock).toHaveBeenCalled()

        it "calls .unlock() when receiving the event unlock-column", ->
            spyOn(columnMenu, "unlock")
            columnMenu.handleAction("unlock-column")
            expect(columnMenu.unlock).toHaveBeenCalled()


    describe ".hide()", ->
        it "hides the column with the correct index", ->
            spyOn(dataTable, "fnSetColumnVis")
            columnMenu.hide()
            expect(dataTable.fnSetColumnVis).toHaveBeenCalledWith(columnIndex, false)


    describe ".showModal()", ->
        modalTrigger = null
        modal        = null
        showTrigger  = null
        other        = null

        beforeEach ->
            modal        = $('<div id="showmodal-modal"/>')
            modalTrigger = $('<a href="#showmodal-modal"/>')
            $("body").append(modal)

            showTrigger  = $('<a/>').addClass("show-column-action")
            other       = $('<a/>')
            modal.append(showTrigger)
            modal.append(other)

            spyOn(columnMenu, "show")

        afterEach ->
            modal.remove()

        it "displays the modal targeted by the modal trigger", ->
            columnMenu.showModal(modalTrigger)
            expect(modal).toHaveData("modal")
            expect(modal.data("modal").options.backdrop).toBe true

        it "binds .populateShowModal() to the shown event, once", ->
            spyOn(columnMenu, "populateShowModal")
            columnMenu.showModal(modalTrigger)

            modal.trigger("shown")
            modal.trigger("shown")

            expect(columnMenu.populateShowModal.calls.length).toBe 1
            expect(columnMenu.populateShowModal).toHaveBeenCalledWith(modal)

        it "binds .show() to the click event of show-column-action elements, once", ->
            columnMenu.showModal(modalTrigger)

            showTrigger.data("column-index", 123)

            showTrigger.trigger("click")
            showTrigger.trigger("click")

            expect(columnMenu.show.calls.length).toBe 1
            expect(columnMenu.show).toHaveBeenCalledWith(123)

        it "does not call the show method for non-matching triggers", ->
            columnMenu.showModal(modalTrigger)
            other.trigger("click")
            expect(columnMenu.show).not.toHaveBeenCalled()

        it "hides the modal when the a column has been selected", ->
            columnMenu.showModal(modalTrigger)
            expect(modal).toBeVisible()
            showTrigger.trigger("click")
            expect(modal).not.toBeVisible()


    describe ".populateShowModal()", ->
        modal     = null
        aoColumns = null

        beforeEach ->
            modal = $("<div/>")
            modal.append($("<ul/>").append($("<li/>").text("zomg")))

            aoColumns = [
                { bVisible: false, nTh: $("<i/>").text("foo") },
                { bVisible: true,  nTh: $("<i/>").text("bar") },
                { bVisible: true,  nTh: $("<i/>").text("apa") },
                { bVisible: false, nTh: $("<i/>").text("baz") }
            ]

            columnMenu.dataTable = fnSettings: -> aoColumns: aoColumns

        it "populates the list with buttons for all hidden columns", ->
            columnMenu.populateShowModal(modal)
            expect(modal.find("button.show-column-action").length).toBe 2
            expect(modal.find("ul").text()).toEqual "foobaz"


    describe ".show()", ->
        beforeEach ->
            columnMenu.dataTable.fnSetColumnVis = ->
            columnMenu.dataTable.fnColReorder = ->
            columnMenu.dataTable._fnSaveState = ->

            spyOn(columnMenu.dataTable, "fnSetColumnVis")
            spyOn(columnMenu.dataTable, "fnColReorder")
            spyOn(columnMenu.dataTable, "_fnSaveState")

        it "shows the requested column", ->
            columnMenu.show(3)
            expect(columnMenu.dataTable.fnSetColumnVis).toHaveBeenCalledWith(3, true)

        it "saves the state of the datatable", ->
            columnMenu.show(3)
            expect(columnMenu.dataTable._fnSaveState).toHaveBeenCalled()

        it "moves the shown column right after the source column when the shown column is somewhere before the source column", ->
            columnMenu.columnIndex = 2
            columnMenu.show(0)
            expect(columnMenu.dataTable.fnColReorder).toHaveBeenCalledWith(0, 2)

        it "moves the shown column right after the source column when the shown column is somewhere after the source column", ->
            columnMenu.columnIndex = 1
            columnMenu.show(3)
            expect(columnMenu.dataTable.fnColReorder).toHaveBeenCalledWith(3, 2)


    describe ".fixedCount()", ->
        it "returns the number of fixed columns in the data table", ->
            columnMenu.dataTable.fnSettings = -> _oFixedColumns: s: iLeftColumns: 123
            expect(columnMenu.fixedCount()).toEqual 123

        it "handles when there are no fixed columns", ->
            columnMenu.dataTable.fnSettings = -> {}
            expect(columnMenu.fixedCount()).toEqual 0


    describe ".lock()", ->
        beforeEach ->
            columnMenu.fixedCount             = -> 3
            columnMenu.columnIndex            = 5
            columnMenu.dataTable.fnColReorder = ->
            columnMenu.dataTable._fnSaveState = ->
            columnMenu.dataTable.trigger      = ->

            spyOn(columnMenu.dataTable, "fnColReorder")
            spyOn(columnMenu.dataTable, "_fnSaveState")
            spyOn(columnMenu.dataTable, "trigger")
            spyOn(jQuery.fn.dataTable,  "FixedColumns")

        it "moves the column to the correct position", ->
            columnMenu.lock()
            expect(columnMenu.dataTable.fnColReorder).toHaveBeenCalledWith(5, 3)

        it "triggers a destroy event for the fixed columns on the data table", ->
            columnMenu.lock()
            expect(columnMenu.dataTable.trigger).toHaveBeenCalledWith("destroy.dt.DTFC")

        it "(re)creates a fixed columns object for the data table", ->
            columnMenu.lock()
            expect(jQuery.fn.dataTable.FixedColumns).toHaveBeenCalledWith(
                columnMenu.dataTable,
                sHeightMatch:  "none"
                iLeftColumns:  4
                iRightColumns: 0
            )

        it "saves the datatable state", ->
            columnMenu.lock()
            expect(columnMenu.dataTable._fnSaveState).toHaveBeenCalled()


    describe ".unlock()", ->
        beforeEach ->
            columnMenu.fixedCount             = -> 5
            columnMenu.columnIndex            = 3
            columnMenu.dataTable.fnColReorder = ->
            columnMenu.dataTable._fnSaveState = ->
            columnMenu.dataTable.trigger      = ->

            spyOn(columnMenu.dataTable, "fnColReorder")
            spyOn(columnMenu.dataTable, "_fnSaveState")
            spyOn(columnMenu.dataTable, "trigger")
            spyOn(jQuery.fn.dataTable,  "FixedColumns")

        it "moves the column to the correct position", ->
            columnMenu.unlock()
            expect(columnMenu.dataTable.fnColReorder).toHaveBeenCalledWith(3, 4)

        it "triggers a destroy event for the fixed columns on the data table", ->
            columnMenu.unlock()
            expect(columnMenu.dataTable.trigger).toHaveBeenCalledWith("destroy.dt.DTFC")

        it "(re)creates a fixed columns object for the data table", ->
            columnMenu.unlock()
            expect(jQuery.fn.dataTable.FixedColumns).toHaveBeenCalledWith(
                columnMenu.dataTable,
                sHeightMatch:  "none"
                iLeftColumns:  4
                iRightColumns: 0
            )

        it "does not create a fixed columns object if the last column was removed", ->
            columnMenu.fixedCount  = -> 1
            columnMenu.columnIndex = 1
            columnMenu.unlock()
            expect(jQuery.fn.dataTable.FixedColumns).not.toHaveBeenCalled()

        it "saves the datatable state", ->
            columnMenu.unlock()
            expect(columnMenu.dataTable._fnSaveState).toHaveBeenCalled()


