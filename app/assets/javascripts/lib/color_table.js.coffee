###
Main functionality for creating a color table
###

class ColorTable
    constructor: (@colorTable, @columns, data) ->

        setTableHeight.call(this)

        options =
            enableColumnReorder:  true
            rowHeight:            32
            formatterFactory:     Formatters

        # Dataview and grid
        @dataView = new Slick.Data.DataView()
        @grid     = new Slick.Grid(@colorTable, @dataView, @columns, options)

        # Refreshing
        @dataView.onRowsChanged.subscribe (e, args) => redrawRows.call(this, args.rows)

        # Sorting
        @grid.onSort.subscribe (e, args) => @sortBy(args.sortCol, args.sortAsc)

        # Row metadata
        @dataView.getItemMetadata = rowMetadata.call(this, @dataView.getItemMetadata)

        loadData.call(this, data)
        @sortBy("student-name", true)


    setTableHeight = ->
        offset = @colorTable.offset()
        @colorTable.height($(document).height() - offset.top - 20)


    loadData = (data) ->
        @dataView.beginUpdate()
        @dataView.setItems(data)
        @dataView.endUpdate()
        @grid.invalidate()


    redrawRows = (rows) ->
        @grid.invalidateRows(rows)
        @grid.render()


    sortBy: (column, asc) ->
        if typeof(column) == "string"
            colIdx = @grid.getColumnIndex(column)
            return if colIdx == undefined

            @grid.setSortColumn(column, asc)
            column = @grid.getColumns()[colIdx]
        else
            @grid.setSortColumn(column.id, asc)

        @dataView.sort @compareValues(column, asc)

    compareValues: (column, asc) ->
        (row1, row2) ->
            # Average row, always last
            return  1 if row1.id == 0
            return -1 if row2.id == 0

            val1 = row1[column.field]
            val2 = row2[column.field]

            # Handle complex structures
            if typeof(val1) == "object" && val1
                val1 = val1["value"]
            if typeof(val2) == "object" && val2
                val2 = val2["value"]

            return  0 if val1 == val2

            # Undefined values are always just above the average row
            return  1 if val1 == undefined
            return -1 if val2 == undefined

            # Null values are always just above the undefined
            return  1 if val1 == null
            return -1 if val2 == null

            # Dash values are always just above the nulls
            return  1 if val1 == "-"
            return -1 if val2 == "-"

            # Compare integers
            if asc
                if val1 > val2 then 1 else -1
            else
                if val1 > val2 then -1 else 1


    rowMetadata = (original) ->
        (row) =>
            if item = @dataView.getItemByIdx(row)
                return { cssClasses: "averages" } if item.id == 0

            return original(row)

window.Digilys ?= {}
window.Digilys.ColorTable = ColorTable


###
Formatters
###

Formatters = {}

Formatters.getFormatter = (item) ->
    if item["type"] == "evaluation"
        return Formatters.ColorCell
    else
        return undefined

Formatters.ColorCell = (row, cell, value, columnDef, dataContext)->
    t = typeof(value)

    return value if t == "number"
    return ""    if t != "object" || !value

    if value["stanine"]
        return "<span class=\"value\">#{value["display"]}</span><span class=\"stanine\">#{value["stanine"]}</span>"
    else
        return value["display"]

window.Digilys.ColorTableFormatters = Formatters
