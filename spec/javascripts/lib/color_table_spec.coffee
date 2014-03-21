describe "Digilys.ColorTable", ->
    container  = null
    table      = null
    columns    = null
    data       = null
    columnMenu = null

    beforeEach ->
        container = $("<div/>")
            .attr("id", "color-table").css({
                width:  "640px"
                height: "480px"
            })
            .attr("data-search-placeholder", "search-placeholder")
            .data("show-column-modal",       "#showmodal-modal")

        columns    = []
        data       = []
        columnMenu = []

    describe "constructor", ->
        beforeEach ->
            columns = [
                { id: "student-name", name: "Student name", field: "sn", sortable: true },
                { id: "col1",         name: "Col 1",        field: "c1", sortable: true }
            ]

            data = [
                { id: 1, sn: "foo", c1: "apa" },
                { id: 2, sn: "bar", c1: "bepa" },
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "correctly assigns the arguments", ->
            expect(table.colorTable).toBe(container)
            expect(table.columns).toBe(columns)
            expect(table.columnMenu).toBe(columnMenu)

        it "initializes a grid, data view, and plugins", ->
            expect(table.dataView.constructor).toBe(Slick.Data.DataView)
            expect(table.grid.constructor).toBe(Slick.Grid)
            expect(table.headerMenu.constructor).toBe(Slick.Plugins.HeaderMenu)

        it "initializes the grid with default options", ->
            options = table.grid.getOptions()
            expect(options.explicitInitialization).toBe(true)
            expect(options.enableColumnReorder).toBe(true)
            expect(options.rowHeight).toBe(32)
            expect(options.formatterFactory).toBe(Digilys.ColorTableFormatters)
            expect(options.showHeaderRow).toBe(true)
            expect(options.headerRowHeight).toBe(45)
            expect(options.frozenColumn).toBe(-1)

        it "resizes the table container to fit the window", ->
            expect(container.height()).toEqual($(document).height() - container.offset().top - 20)

        it "renders the grid", ->
            expect(container.find(".slick-row")).toHaveLength(2)

        it "adds filter inputs to the header row", ->
            inputs = container.find(".slick-headerrow :text[placeholder=search-placeholder]")
            expect(inputs).toHaveLength(2)

        it "sorts by the student name by default", ->
            expect(container.find(".slick-header-column-sorted .slick-column-name")).toHaveText("Student name")
            expect(container.find(".slick-sort-indicator")).toHaveClass("slick-sort-indicator-asc")

        it "displays sorting changes", ->
            container.find(".slick-header-column:not(.slick-header-column-sorted)").trigger("click")
            expect(container.find(".slick-header-column-sorted .slick-column-name")).toHaveText("Col 1")

    describe "event subscriptions", ->
        beforeEach ->
            table = new Digilys.ColorTable(container, columns, data, columnMenu)

            spyOn(table, "sortBy")

        it "grid.onSort calls .sortBy()", ->
            table.grid.onSort.notify({ sortCol: "sortcol", sortAsc: "lol" }, new Slick.EventData())
            expect(table.sortBy).toHaveBeenCalledWith("sortcol", "lol")
            expect(table.sortBy).toHaveBeenCalledOn(table)


    describe ".sortBy()", ->
        beforeEach ->
            columns = [
                { id: "student-name", name: "Student name", field: "sn", headerCssClass: "sn", sortable: true },
                { id: "col1",         name: "Col 1",        field: "c1", headerCssClass: "c1", sortable: true }
            ]

            data = [
                { id: 1, sn: "foo", c1: "bepa" },
                { id: 2, sn: "bar", c1: "apa" },
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)
            spyOn(table, "compareValues").and.callThrough()

        it "sorts by the specified column", ->
            table.sortBy(columns[1], true)
            expect(container.find(".slick-header-column-sorted")).toHaveClass("c1")
            expect(container.find(".slick-sort-indicator")).toHaveClass("slick-sort-indicator-asc")

            table.sortBy(columns[1], false)
            expect(container.find(".slick-header-column-sorted")).toHaveClass("c1")
            expect(container.find(".slick-sort-indicator")).toHaveClass("slick-sort-indicator-desc")

        it "supports using a column id", ->
            table.sortBy("col1", true)
            expect(container.find(".slick-header-column-sorted")).toHaveClass("c1")
            expect(container.find(".slick-sort-indicator")).toHaveClass("slick-sort-indicator-asc")
            table.sortBy("col1", false)
            expect(container.find(".slick-header-column-sorted")).toHaveClass("c1")
            expect(container.find(".slick-sort-indicator")).toHaveClass("slick-sort-indicator-desc")

        it "sorts using .compareValues()", ->
            table.sortBy(columns[0], true)
            expect(table.compareValues).toHaveBeenCalled()

    describe ".compareValues()", ->
        f      = null
        column = null

        beforeEach ->
            data = [
                { id: 1, f: { value: 3 } },
                { id: 0, f: 0 },
                { id: 3, f: 8 },
                { id: 8, f: { value: null } },
                { id: 4, f: "-" },
                { id: 5, f: 7 },
                { id: 6, f: undefined }
            ]

            f = Digilys.ColorTable::compareValues

        describe "ascending", ->

            it "sorts by value, placing averages last and any invalid values at the end", ->
                data.sort(f({ field: "f" }, true))
                ids = (d.id for d in data)
                expect(ids).toEqual([1,5,3,4,8,6,0])

        describe "descending", ->

            it "sorts by value, placing averages last and any invalid values at the end", ->
                data.sort(f({ field: "f" }, false))
                ids = (d.id for d in data)
                expect(ids).toEqual([3,5,1,4,8,6,0])


    describe "row metadata", ->
        beforeEach ->
            columns = [{id: "col", name: "col", field: "f", sortable: true}]
            data = [
                { id: 0, f: 0},
                { id: 1, f: 1}
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "adds the css class 'averages' to the row with id 0", ->
            expectedLength = if table.grid.getOptions()["frozenColumn"] > -1 then 2 else 1
            expect(container.find(".slick-row.averages")).toHaveLength(expectedLength)

    describe "cell metadata", ->
        beforeEach ->
            columns = [{id: "col", name: "col", field: "f", sortable: true}]
            data = [
                { id: 0, f: { display: "z", cssClass: "zomglol" } },
                { id: 1, f: 1 }
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "adds a css class to the cell (patched in slick.grid.js)", ->
            expect(container.find(".slick-cell.zomglol")).toHaveLength(1)


    describe "filtering", ->
        nameInput = null
        col1Input = null

        beforeEach ->
            columns = [
                { id: "student-name", name: "Student name", field: "sn", sortable: true },
                { id: "col1",         name: "Col 1",        field: "c1", sortable: true }
            ]

            data = [
                { id: 1, sn: "foo", c1: "apa" },
                { id: 2, sn: "bar", c1: "bepa" },
                { id: 3, sn: "foo", c1: "cepa" },
                { id: 4, sn: "bar", c1: "cepa" },
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

            inputs = container.find(".slick-headerrow :text[placeholder=search-placeholder]")
            nameInput = $(inputs[0])
            col1Input = $(inputs[1])

        it "filters by column", ->
            expect(container.find(".slick-row")).toHaveLength(4)
            nameInput.val("oo")
            nameInput.trigger("change")
            expect(container.find(".slick-row")).toHaveLength(2)
            expect(container.find(".slick-row")).toHaveText("fooapafoocepa")

        it "filters by multiple columns", ->
            nameInput.val("oo")
            nameInput.trigger("keyup")
            col1Input.val("c")
            col1Input.trigger("change")

            expect(container.find(".slick-row")).toHaveLength(1)
            expect(container.find(".slick-row")).toHaveText("foocepa")

    describe ".groupFilter()", ->
        beforeEach ->
            columns = [
                { id: "student-name", name: "Student name", field: "sn", sortable: true }
            ]

            data = [
                { id: 1, sn: "student1", groups: [1,2] },
                { id: 2, sn: "student1", groups: [1] },
                { id: 3, sn: "student3", groups: [2] },
                { id: 4, sn: "student4", groups: [3] },
                { id: 5, sn: "student5", groups: [] },
                { id: 6, sn: "student6", groups: [] },
                { id: 7, sn: "student7" }
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)
            expect(container.find(".slick-row")).toHaveLength(7)

        it "shows only students in any of the selected groups", ->
            table.groupFilter(["1", "2"])
            expect(container.find(".slick-row")).toHaveLength(3)

        it "shows all students when resetting to a blank filter", ->
            table.groupFilter(["1", "2"])
            expect(container.find(".slick-row")).toHaveLength(3)
            table.groupFilter([])
            expect(container.find(".slick-row")).toHaveLength(7)

    describe "column header height", ->
        left  = null
        right = null
        style = null

        beforeEach ->
            columns = [
                { id: "student-name", name: "Student name", field: "sn", sortable: true, headerCssClass: "sname" },
                { id: "col1",         name: "Col 1",        field: "c1", sortable: true, headerCssClass: "col1" }
            ]

            data = [
                { id: 1, sn: "foo", c1: "apa" },
                { id: 2, sn: "bar", c1: "bepa" },
                { id: 3, sn: "foo", c1: "cepa" },
                { id: 4, sn: "bar", c1: "cepa" },
            ]
            container.appendTo($("body"))
            style = $("<style type='text/css' rel='stylesheet' />").appendTo($("head"))

        afterEach ->
            style.remove()
            container.remove()

        it "makes the column header heights equal when the frozen is larger", ->
            style.text(".slick-header-column.sname { height: 40px; }; .slick-header-column.col1 { height: 20px; }; ")
            table = new Digilys.ColorTable(container, columns, data, columnMenu)
            table.lockColumn("student-name")

            nameHeader = container.find(".slick-header-column.sname")
            col1Header = container.find(".slick-header-column.col1")

            expect(nameHeader.height()).toEqual(col1Header.height())

        it "makes the column header heights equal when the frozen is smaller", ->
            style.text(".slick-header-column.sname { height: 40px; }; .slick-header-column.col1 { height: 60px; }; ")
            table = new Digilys.ColorTable(container, columns, data, columnMenu)
            table.lockColumn("student-name")

            nameHeader = container.find(".slick-header-column.sname")
            col1Header = container.find(".slick-header-column.col1")

            expect(nameHeader.height()).toEqual(col1Header.height())


    describe "column titles", ->
        beforeEach ->
            columns = [
                { id: "student-name", name: "Student name", field: "sn", sortable: true, title: "sname" },
                { id: "col1",         name: "Col 1",        field: "c1", sortable: true }
            ]
            data = [ { id: 1, sn: "foo", c1: "apa" } ]

            node = $("<div/>").get(0)

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "adds a title to the column node", ->
            expect(container.find(".slick-header-column[title=sname]")).toHaveLength(1)

        it "does not add a title attribute when there is no title", ->
            expect(container.find(".slick-header-column[title='']")).toHaveLength(1)


    describe ".hideColumn()", ->
        beforeEach ->
            columns = [
                { id: "col1", name: "col1", field: "col1", cssClass: "col1" },
                { id: "col2", name: "col2", field: "col2", cssClass: "col2" },
                { id: "col3", name: "col3", field: "col3", cssClass: "col3" }
            ]

            data = [
                { id: 1, col1: "1-col1", col2: "1-col2", col3: "1-col3" }
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "removes the column from the grid", ->
            table.hideColumn(columns[1])
            expect(container.find(".slick-header-column")).toHaveLength(2)
            expect(container.find(".col2")).toHaveLength(0)

        it "handles invalid columns", ->
            table.hideColumn({})
            expect(container.find(".slick-header-column")).toHaveLength(3)

    describe ".showColumn()", ->
        beforeEach ->
            columns = [
                { id: "frozen", name: "col1", field: "col1", headerCssClass: "col1" },
                { id: "col2", name: "col2", field: "col2", headerCssClass: "col2" },
                { id: "col3", name: "col3", field: "col3", headerCssClass: "col3" },
                { id: "col4", name: "col3", field: "col3", headerCssClass: "col3" }
            ]

            data = [
                { id: 1, frozen: "1-col1", col2: "1-col2", col3: "1-col3", col4: "1-col4" }
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "adds the column to the grid after the specified column", ->
            col = columns[3]
            table.hideColumn(col)
            table.showColumn(col.id, columns[1])
            expect(container.find(".slick-header-column")).toHaveLength(4)
            expect(container.find(".col3").index()).toBe(2)


    describe ".lockColumn()", ->
        beforeEach ->
            columns = [
                { id: "col1", name: "col1", field: "col1", headerCssClass: "col1" },
                { id: "col2", name: "col2", field: "col2", headerCssClass: "col2" },
                { id: "col3", name: "col3", field: "col3", headerCssClass: "col3" }
            ]

            data = [
                { id: 1, col1: "1-col1", col2: "1-col2", col3: "1-col3" }
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "locks the specified column to the left", ->
            expect(container.find(".slick-header-columns-left").children()).toHaveLength(3)

            table.lockColumn("col2")

            expect(container.find(".slick-header-columns-left").children()).toHaveLength(1)
            expect(container.find(".slick-header-columns-right").children()).toHaveLength(2)

            expect(container.find(".slick-header-columns-left").children(":first")).toHaveClass("col2")

        it "adds a locked column to the end of the already locked columns", ->
            table.lockColumn("col3")
            table.lockColumn("col2")

            expect(container.find(".slick-header-columns-right").children()).toHaveLength(1)

            children = container.find(".slick-header-columns-left").children()

            expect(children).toHaveLength(2)
            expect(children).toHaveText("col3col2")

        it "handles invalid column ids", ->
            table.lockColumn("unknown")
            expect(container.find(".slick-header-columns-left").children()).toHaveLength(3)

    describe ".unlockColumn()", ->
        beforeEach ->
            columns = [
                { id: "col1", name: "col1", field: "col1", headerCssClass: "col1" },
                { id: "col2", name: "col2", field: "col2", headerCssClass: "col2" },
                { id: "col3", name: "col3", field: "col3", headerCssClass: "col3" }
            ]

            data = [
                { id: 1, col1: "1-col1", col2: "1-col2", col3: "1-col3" }
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)
            table.lockColumn("col1")
            table.lockColumn("col2")

        it "unlocks the column", ->
            expect(container.find(".slick-header-columns-left .col2")).toHaveLength(1)

            table.unlockColumn("col2")

            expect(container.find(".slick-header-columns-left .col2")).toHaveLength(0)
            expect(container.find(".slick-header-columns-right .col2")).toHaveLength(1)

        it "moves the unlocked column to just after the locked columns", ->
            table.unlockColumn("col1")
            expect(container.find(".slick-header-columns-right .slick-header-column")).toHaveClass("col1")

        it "handles invalid column ids", ->
            table.lockColumn("unknown")
            expect(container.find(".slick-header-columns-left").children()).toHaveLength(2)


    describe "column menu", ->
        node = null

        beforeEach ->
            columns = [
                { id: "col1", name: "col1", field: "col1", headerCssClass: "col1", header: { menu: { items: [] } } }
                { id: "col2", name: "col2", field: "col2", headerCssClass: "col2", header: { menu: { items: [] } } }
                { id: "col3", name: "col3", field: "col3", headerCssClass: "col3", header: { menu: { items: [] } } }
            ]
            columnMenu = [
                { title: "hide",   command: "hide"   },
                { title: "show",   command: "show"   },
                { title: "lock",   command: "lock"   },
                { title: "unlock", command: "unlock" },
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)

        it "does not include the show command when there are no hidden columns", ->
            container.find(".col1 .slick-header-menubutton").trigger("click")
            menuItems = container.find(".slick-header-menu .slick-header-menuitem")
            expect(menuItems).toHaveLength(2)
            expect(menuItems).toHaveText("hidelock")

        it "includes the entire column menu if there are hidden columns", ->
            table.hideColumn(columns[1])
            container.find(".col1 .slick-header-menubutton").trigger("click")
            menuItems = container.find(".slick-header-menu .slick-header-menuitem")
            expect(menuItems).toHaveLength(3)
            expect(menuItems).toHaveText("hideshowlock")

        it "does not include the unlock command when the column is not locked", ->
            container.find(".col1 .slick-header-menubutton").trigger("click")
            menuItems = container.find(".slick-header-menu .slick-header-menuitem")
            expect(menuItems).toHaveLength(2)
            expect(menuItems).toHaveText("hidelock")

        it "does not include the lock command when the column is locked", ->
            table.lockColumn("col1")
            container.find(".col1 .slick-header-menubutton").trigger("click")
            menuItems = container.find(".slick-header-menu .slick-header-menuitem")
            expect(menuItems).toHaveLength(2)
            expect(menuItems).toHaveText("hideunlock")

        it "hides the column when clicking the hide entry", ->
            container.find(".col1 .slick-header-menubutton").trigger("click")
            container.find(".slick-header-menuitem:first").trigger("click")
            expect(container.find(".col1")).toHaveLength(0)

        it "locks the column when clicking the lock entry", ->
            container.find(".col1 .slick-header-menubutton").trigger("click")
            $(container.find(".slick-header-menuitem")[1]).trigger("click")

            expect(container.find(".slick-header-columns-left").children()).toHaveLength(1)
            expect(container.find(".slick-header-columns-left .col1")).toHaveLength(1)
            expect(container.find(".slick-header-columns-right .col1")).toHaveLength(0)

        it "unlocks the column when clicking the unlock entry", ->
            table.lockColumn("col1")
            container.find(".col1 .slick-header-menubutton").trigger("click")
            $(container.find(".slick-header-menuitem")[1]).trigger("click")

            expect(container.find(".slick-header-columns-left").children()).toHaveLength(3)
            expect(container.find(".slick-header-columns-right").children()).toHaveLength(0)

        describe "showing columns", ->
            modal = null

            beforeEach ->
                modal = $('<div id="showmodal-modal" style="display:none"/>').append("<ul/>")
                $("body").append(modal)

                table.hideColumn(columns[1]) # Hide col2

            afterEach ->
                modal.remove()

            it "shows a modal with all hidden columns", ->
                table.hideColumn(columns[1]) # Hide col3, original array is modified

                container.find(".col1 .slick-header-menubutton").trigger("click")
                $(container.find(".slick-header-menuitem")[1]).trigger("click")

                expect(modal).toBeVisible()
                expect(modal.find("button")).toHaveLength(2)
                expect(modal.find("button")).toHaveText("col2col3")

            it "shows the column when clicking the show entry and selecting a column in the triggered modal", ->
                container.find(".col3 .slick-header-menubutton").trigger("click")
                $(container.find(".slick-header-menuitem")[1]).trigger("click")

                modal.find("button").trigger("click")

                expect(modal).not.toBeVisible()
                expect(container.find(".slick-header-column")).toHaveLength(3)

            it "adds the shown column after the column where the menu was shown", ->
                container.find(".col3 .slick-header-menubutton").trigger("click")
                $(container.find(".slick-header-menuitem")[1]).trigger("click")

                modal.find("button").trigger("click")

                expect(modal).not.toBeVisible()
                expect(container.find(".slick-header-column")).toHaveText("col1col3col2")


    describe "state change event", ->
        beforeEach ->
            columns = [
                {
                    id:             "col1",
                    name:           "col1",
                    field:          "col1",
                    sortable:       true,
                    cssClass:       "col1",
                    headerCssClass: "col1",
                    header:         { menu: { items: [] } }
                },
                {
                    id:             "col2",
                    name:           "col2",
                    field:          "col2",
                    sortable:       true,
                    cssClass:       "col2",
                    headerCssClass: "col2",
                    header:         { menu: { items: [] } }
                },
                {
                    id:             "col3",
                    name:           "col3",
                    field:          "col3",
                    sortable:       true,
                    cssClass:       "col3",
                    headerCssClass: "col3",
                    header:         { menu: { items: [] } }
                }
            ]
            columnMenu = [
                { title: "hide",   command: "hide"   },
                { title: "show",   command: "show"   },
                { title: "lock",   command: "lock"   },
                { title: "unlock", command: "unlock" }
            ]

            table = new Digilys.ColorTable(container, columns, data, columnMenu)
            table.lockColumn("col1")
            table.hideColumn(columns[2])

            spyOnEvent(container, "state-change")

        afterEach ->
            expect("state-change").toHaveBeenTriggeredOnAndWith(container, table)

        it "is triggered when the sorting changes", ->
            container.find(".col2 .slick-column-name").trigger("click")

        it "is triggered when the column order changes", ->
            # Hard to test drag-and-drop, so just trigger the event
            table.grid.onColumnsReordered.notify({}, new Slick.EventData())

        it "is triggered when the column filter changes", ->
            container.find(".slick-headerrow :text").first().val("x").trigger("change")

        it "is triggered when the group filter changes", ->
            table.groupFilter(["1"])

        it "is triggered when a column is hidden", ->
            container.find(".col1 .slick-header-menubutton").trigger("click")
            menuSelection = container.find(".slick-header-menuitem:first")
            expect(menuSelection).toHaveText("hide")
            menuSelection.trigger("click")

        it "is triggered when a column is shown", ->
            modal = $('<div id="showmodal-modal" style="display:none"/>').append("<ul/>")
            $("body").append(modal)

            container.find(".col1 .slick-header-menubutton").trigger("click")
            menuSelection = $(container.find(".slick-header-menuitem")[1])
            expect(menuSelection).toHaveText("show")
            menuSelection.trigger("click")
            modal.find("button").trigger("click")

            modal.remove()

        it "is triggered when a column is locked", ->
            container.find(".col2 .slick-header-menubutton").trigger("click")
            menuSelection = $(container.find(".slick-header-menuitem")[2])
            expect(menuSelection).toHaveText("lock")
            menuSelection.trigger("click")

        it "is triggered when a column is unlocked", ->
            container.find(".col1 .slick-header-menubutton").trigger("click")
            menuSelection = $(container.find(".slick-header-menuitem")[2])
            expect(menuSelection).toHaveText("unlock")
            menuSelection.trigger("click")


describe "ColorTableFormatters", ->
    F = Digilys.ColorTableFormatters

    describe ".getFormatter()", ->
        it "returns StudentName for student columns", ->
            expect(F.getFormatter(type: "student-name")).toBe(F.StudentNameCell)
        it "returns ColorCell for evaluation columns", ->
            expect(F.getFormatter(type: "evaluation")).toBe(F.ColorCell)
        it "returns undefined for unknown column types", ->
            expect(F.getFormatter(type: "unknown")).toBeUndefined()
            expect(F.getFormatter({})).toBeUndefined()

    describe "StudentNameCell", ->
        StudentNameCell = F.StudentNameCell
        rawResult = null
        result = null

        beforeEach ->
            rawResult = StudentNameCell(0, 0, "Student Name", {}, { id: 123 })
            result    = $(rawResult)

        it "returns a string", ->
            expect(typeof rawResult).toBe("string")

        it "wraps the name in a button", ->
            expect(result).toHaveText("Student Name")
            expect(result).toBeMatchedBy("button.student-action")

        it "adds the student's id as data", ->
            expect(result).toHaveData("id", 123)

        it "does not wrap the result when the id is 0", ->
            expect(StudentNameCell(0, 0, "Student Name", {}, { id: 0 })).toEqual("Student Name")

    describe "ColorCell", ->
        ColorCell = F.ColorCell

        it "returns a blank string for empty values", ->
            expect(ColorCell(0, 0, undefined)).toEqual("")
            expect(ColorCell(0, 0, null)).toEqual("")

        it "returns the number for number values", ->
            expect(ColorCell(0, 0, 12)).toEqual(12)
            expect(ColorCell(0, 0, 12.3)).toEqual(12.3)

        it "returns the display value for results without stanines", ->
            expect(ColorCell(0, 0, {display: "123"})).toEqual("123")

        it "returns two spans with the display value and stanine for results with stanines", ->
            cnt = $("<div/>").html(ColorCell(0, 0, {display: "123", stanine: 4}))
            expect(cnt.find("span")).toHaveLength(2)
            expect(cnt.find(".value")).toHaveText("123")
            expect(cnt.find(".stanine")).toHaveText("4")
