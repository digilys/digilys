describe "Digilys.ColorTable", ->
    container = null
    table     = null
    columns   = null
    data      = null

    beforeEach ->
        container = $("<div/>")
            .attr("id", "color-table").css({
                width:  "640px"
                height: "480px"
            })
            .attr("data-search-placeholder", "search-placeholder")

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

            table = new Digilys.ColorTable(container, columns, data)

        it "correctly assigns the arguments", ->
            expect(table.colorTable).toBe(container)
            expect(table.columns).toBe(columns)

        it "initializes a grid and data view", ->
            expect(table.dataView.constructor).toBe(Slick.Data.DataView)
            expect(table.grid.constructor).toBe(Slick.Grid)

        it "initializes the grid with default options", ->
            options = table.grid.getOptions()
            expect(options.explicitInitialization).toBe(true)
            expect(options.enableColumnReorder).toBe(true)
            expect(options.rowHeight).toBe(32)
            expect(options.formatterFactory).toBe(Digilys.ColorTableFormatters)
            expect(options.showHeaderRow).toBe(true)
            expect(options.headerRowHeight).toBe(45)

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
            columns = []
            data = []

            table = new Digilys.ColorTable(container, columns, data)

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

            table = new Digilys.ColorTable(container, columns, data)
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

            table = new Digilys.ColorTable(container, columns, data)

        it "adds the css class 'averages' to the row with id 0", ->
            expect(container.find(".slick-row.averages")).toHaveLength(1)

    describe "cell metadata", ->
        beforeEach ->
            columns = [{id: "col", name: "col", field: "f", sortable: true}]
            data = [
                { id: 0, f: { display: "z", cssClass: "zomglol" } },
                { id: 1, f: 1 }
            ]

            table = new Digilys.ColorTable(container, columns, data)

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

            table = new Digilys.ColorTable(container, columns, data)

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


describe "ColorTableFormatters", ->
    F = Digilys.ColorTableFormatters

    describe ".getFormatter()", ->
        it "returns ColorCell for evaluation columns", ->
            expect(F.getFormatter(type: "evaluation")).toBe(F.ColorCell)
        it "returns undefined for unknown column types", ->
            expect(F.getFormatter(type: "unknown")).toBeUndefined()
            expect(F.getFormatter({})).toBeUndefined()

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
