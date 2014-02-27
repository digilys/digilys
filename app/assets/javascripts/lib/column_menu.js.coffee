###
Displays a datatable column menu and handles different
actions for the column
###

class ColumnMenu
    constructor: (@dataTable, @columnIndex, menu, @onAction) ->
        @menu = $(menu).clone()
            .attr("id", "")
            .show()

        columns = @dataTable.fnSettings().aoColumns
        hasHiddenColumns = (1 for column in columns when !column.bVisible).length > 0

        @menu.find("[data-action=show-column]").remove() unless hasHiddenColumns

        self = this

        @menu.on "click", "[data-action]", (event) ->
            event.preventDefault()
            trigger = $(this)
            self.handleAction(trigger.data("action"), trigger)


    handleAction: (action, trigger) ->
        switch action
            when "hide-column" then @hide()
            when "show-column" then @showModal(trigger)

        @onAction()


    hide: ->
        @dataTable.fnSetColumnVis(@columnIndex, false)


    show: (shownIdx) ->
        sourceIdx = @columnIndex

        # When moving a column to the left in the table, ColReorder moves the
        # column before the target, so in order to get the column after the source
        # column, we need to increase the target index
        if shownIdx > sourceIdx
            sourceIdx++

        @dataTable.fnSetColumnVis(shownIdx, true)
        @dataTable.fnColReorder(shownIdx, sourceIdx)
        @dataTable._fnSaveState(@dataTable.fnSettings())


    showModal: (trigger) ->
        modal = $(trigger.attr("href"))

        modal.one "shown", => @populateShowModal(modal)

        self = this
        modal.one "click", ".show-column-action", ->
            modal.modal("hide")
            self.show($(this).data("column-index"))

        modal.modal(backdrop: true)


    populateShowModal: (modal) ->
        list = modal.find("ul")
        list.html("")

        for column, i in @dataTable.fnSettings().aoColumns
            if !column.bVisible
                button = $("<button>")
                    .addClass("btn btn-link show-column-action")
                    .data("column-index", i)
                    .text($(column.nTh).text())

                list.append $("<li/>").append(button)


# Export
window.Digilys ?= {}
window.Digilys.ColumnMenu = ColumnMenu
