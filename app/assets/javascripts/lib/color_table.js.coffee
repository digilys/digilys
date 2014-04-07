###
Main functionality for creating a color table
###

class ColorTable
    constructor: (@colorTable, @columns, data, @columnMenu) ->

        setTableHeight.call(this)

        @settings =
            searchPlaceholder: @colorTable.data("search-placeholder")

        @filters       = {}
        @hiddenColumns = []

        options =
            explicitInitialization: true
            enableColumnReorder:    true
            rowHeight:              32
            formatterFactory:       Formatters
            showHeaderRow:          true
            headerRowHeight:        45
            frozenColumn:           -1

        self = this

        # Dataview and grid
        @dataView = new Slick.Data.DataView()
        @grid     = new Slick.Grid(@colorTable, @dataView, @columns, options)

        # State change events
        @stateChange = (e, args) => @colorTable.trigger("state-change", this)
        @grid.onColumnsResized.subscribe   @stateChange
        @grid.onColumnsReordered.subscribe @stateChange

        # Refreshing
        @dataView.onRowsChanged.subscribe (e, args)     => redrawRows.call(this, args.rows)
        @dataView.onRowCountChanged.subscribe (e, args) => redrawRows.call(this, args.rows)

        # Sorting
        @grid.onSort.subscribe (e, args) =>
            @sortBy(args.sortCol, args.sortAsc)
            @stateChange()

        # Filtering
        @grid.onHeaderRowCellRendered.subscribe (e, args) =>
            buildFilterInput($(args.node), args.column.id, @settings.searchPlaceholder)

        @colorTable.on "change keyup", ":input", ->
            elem = $(this)
            self.filters[elem.data("column-id")] = elem.val()
            self.dataView.refresh()
            self.stateChange()

        # Row metadata
        @dataView.getItemMetadata = rowMetadata.call(this, @dataView.getItemMetadata)

        # Column header heights
        @grid.onHeadersRendered.subscribe (e, args) -> setHeaderHeight($(args.leftNode), $(args.rightNode))

        # Column titles
        @grid.onHeaderCellRendered.subscribe (e, args) -> setColumnTitle(args.column, args.node)

        # Header menu
        @headerMenu = new Slick.Plugins.HeaderMenu({})
        @headerMenu.onBeforeMenuShow.subscribe (e, args) => setMenu.call(this, args.menu, args.column)
        @headerMenu.onCommand.subscribe (e, args)        => menuCommand.call(this, args.command, args.column)
        @grid.registerPlugin(@headerMenu)

        @grid.init()

        loadData.call(this, data)
        @sortBy("student-name", true)

        @colorTable.data("color-table", this)


    setTableHeight = ->
        offset = @colorTable.offset()
        @colorTable.height($(document).height() - offset.top - 20)

    setHeaderHeight = (leftHeader, rightHeader) ->
        leftHeight  = leftHeader.children(":first").height()
        rightHeight = rightHeader.children(":first").height()

        if leftHeight > rightHeight
            rightHeader.children().height(leftHeight)
        else if rightHeight > leftHeight
            leftHeader.children().height(rightHeight)


    loadData = (data) ->
        @dataView.beginUpdate()
        @dataView.setItems(data)
        @dataView.setFilter(createFilter(@grid, @filters))
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


    buildFilterInput = (container, columnId, placeholder) ->
        container.html(
            $("<input type=\"text\">")
                .data("column-id", columnId)
                .attr("placeholder", placeholder)
        )

    createFilter = (grid, filters) ->
        (item) ->
            return true if item.id == 0

            for columnId, filter of filters when filter && filter.length > 0

                if columnId == "groups"
                    return false if !item.groups || item.groups.length <= 0

                    any = false
                    for id in filter when id in item.groups
                        any = true
                        break

                    return false unless any

                else
                    columnIdx = grid.getColumnIndex(columnId)

                    if columnIdx != undefined

                        column = grid.getColumns()[columnIdx]

                        value = item[column.field]

                        return false if !value

                        if typeof(value) == "object"
                            value = value["display"]

                        return false if value.toLowerCase().indexOf(filter.toLowerCase()) == -1

            return true

    groupFilter: (groupIds) ->
        if groupIds && groupIds.length > 0
            @filters.groups = (parseInt(id) for id in groupIds when id.match(/^\d+$/))
        else
            @filters.groups = []

        @dataView.refresh()
        @stateChange()


    setColumnTitle = (column, node) ->
        node.setAttribute("title", column.title) if column.title


    hideColumn: (column) ->
        columns = @grid.getColumns()

        if (idx = columns.indexOf(column)) >= 0
            @hiddenColumns.push(columns.splice(idx, 1)[0])
            @grid.setColumns(columns)
            @stateChange()

    showColumn: (columnId, after) ->
        hidden = (c for c in @hiddenColumns when c.id == columnId)[0]
        return unless hidden
        
        columns = @grid.getColumns()

        if (idx = columns.indexOf(after)) >= 0
            columns.splice(idx + 1, 0, hidden)
            @hiddenColumns.splice(@hiddenColumns.indexOf(hidden), 1)
            @grid.setColumns(columns)
            @stateChange()


    lockColumn: (columnId) ->
        columns = @grid.getColumns()

        # Find column index based on its id
        idx = (i for col, i in columns when col.id == columnId)[0]

        return if idx == undefined

        num = @grid.getOptions().frozenColumn + 1

        # Move the column to the last frozen position
        column = columns.splice(idx, 1)[0]
        columns.splice(num, 0, column)

        @grid.setColumns(columns)
        @grid.setOptions(frozenColumn: num)
        @stateChange()

    unlockColumn: (columnId) ->
        columns = @grid.getColumns()

        # Find column index based on its id
        idx = (i for col, i in columns when col.id == columnId)[0]

        return if idx == undefined

        num = @grid.getOptions().frozenColumn - 1

        # Move the column to the just after the last frozen position
        column = columns.splice(idx, 1)[0]
        columns.splice(num + 1, 0, column)

        @grid.setColumns(columns)
        @grid.setOptions(frozenColumn: num)
        @stateChange()


    setMenu = (menu, column) ->
        menu.items = []

        for m in @columnMenu
            continue if m.command == "show"   && @hiddenColumns.length <= 0
            continue if m.command == "lock"   && column.frozen
            continue if m.command == "unlock" && !column.frozen

            menu.items.push(m)

    menuCommand = (command, column) ->
        switch command
            when "hide"   then @hideColumn(column)
            when "show"   then showModal.call(this, column)
            when "lock"   then @lockColumn(column.id)
            when "unlock" then @unlockColumn(column.id)


    showModal = (column) ->
        modal = $(@colorTable.data("show-column-modal"))

        modal.one "shown", => populateShowModal.call(this, modal)

        self = this
        modal.one "click", ".show-column-action", ->
            modal.modal("hide")
            self.showColumn($(this).data("column-id"), column)

        modal.modal(backdrop: true)

    populateShowModal = (modal) ->
        list = modal.find("ul")
        list.html("")

        for column in @hiddenColumns
            button = $("<button>")
                .addClass("btn btn-link show-column-action")
                .data("column-id", column.id)
                .text(column.name)

            list.append $("<li/>").append(button)


    getState: () ->
        state = {}

        # Sort column
        state.sort = @grid.getSortColumns()

        # Column order and widths
        columns = @grid.getColumns()
        state.columnOrder = []
        state.columnWidths = {}

        for c in columns
            state.columnOrder.push(c.id)
            state.columnWidths[c.id] = c.width

        # Filters
        state.filters = @filters

        # Locked columns
        state.lockedColumns = @grid.getOptions().frozenColumn + 1

        # Hidden columns
        state.hiddenColumns = (c.id for c in @hiddenColumns)

        return state

    setState: (state) ->
        return unless state

        # Sorting
        @sortBy(state.sort[0].columnId, state.sort[0].sortAsc) if state.sort

        columns = @grid.getColumns()

        # Hidden columns (perform before any other column operations)
        if state.hiddenColumns
            @hiddenColumns = []

            for columnId in state.hiddenColumns
                idx = (i for c, i in columns when c.id == columnId)[0]

                if idx != undefined
                    col = columns.splice(idx, 1)
                    @hiddenColumns.push(col[0]) if col.length > 0

        # Column order
        if state.columnOrder
            ordered   = []
            compacted = []
            missing   = []

            for column in columns
                idx = state.columnOrder.indexOf(column.id)

                if idx > -1
                    ordered[idx] = column
                else
                    missing.push(column)

            compacted.push(e) for e in ordered when e != undefined
            columns = compacted.concat(missing)

        # Column widths
        for c in columns when state.columnWidths
            w = state.columnWidths[c.id]
            c.width = w if w != undefined

        @grid.setColumns(columns)

        # Locked columns
        @grid.setOptions(frozenColumn: state.lockedColumns - 1) if state.lockedColumns


        # Filters
        if state.filters
            delete @filters[k] for k, v of @filters

            inputs = @colorTable.find(".slick-headerrow-column :text")

            for k, v of state.filters
                @filters[k] = v
                idx = @grid.getColumnIndex(k)
                if idx != undefined
                    $(inputs[idx]).val(v)

            @dataView.refresh()

window.Digilys ?= {}
window.Digilys.ColorTable = ColorTable


###
Formatters
###

Formatters = {}

Formatters.getFormatter = (item) ->
    switch item.type
        when "student-name" then Formatters.StudentNameCell
        when "evaluation"   then Formatters.ColorCell
        else undefined

Formatters.StudentNameCell = (row, cell, value, columnDef, dataContext) ->
    return value if dataContext.id == 0

    button = $("<button class=\"student-action btn btn-link\" data-id=\"#{dataContext.id}\" data-toggle=\"single-popover\"/>")
        .text(value)
        .attr("data-title", value)
    return button[0].outerHTML

Formatters.ColorCell = (row, cell, value, columnDef, dataContext) ->
    t = typeof(value)

    return value if t == "number"
    return ""    if t != "object" || !value

    if value["stanine"]
        return "<span class=\"value\">#{value["display"]}</span><span class=\"stanine\">#{value["stanine"]}</span>"
    else
        return value["display"]

window.Digilys.ColorTableFormatters = Formatters
