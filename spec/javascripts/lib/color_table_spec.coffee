describe "Digilys.ColorTable", ->
    container = null
    table     = null
    columns   = null
    data      = null

    beforeEach ->
        container = $("<div/>").attr("id", "color-table").css({
            width:  "640px"
            height: "480px"
        })

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
            expect(options.enableColumnReorder).toBe(true)
            expect(options.rowHeight).toBe(32)

        it "resizes the table container to fit the window", ->
            expect(container.height()).toEqual($(document).height() - container.offset().top - 20)

        it "renders the grid", ->
            expect(container.find(".slick-row")).toHaveLength(2)

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
                { id: 1, f: 3},
                { id: 0, f: 0},
                { id: 3, f: 8},
                { id: 8, f: null},
                { id: 4, f: "-"},
                { id: 5, f: 7},
                { id: 6, f: undefined}
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
