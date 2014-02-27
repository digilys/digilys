###
Displays a datatable column menu and handles different
actions for the column
###

class ColumnMenu
    constructor: (@dataTable, @columnIndex, menu, @onAction) ->
        @menu = $(menu).clone()
            .attr("id", "")
            .show()

        self = this
        @menu.on "click", "[data-action]", (event) ->
            event.preventDefault()
            self.handleAction($(this).data("action"))

    handleAction: (action) ->
        switch action
            when "hide-column" then @hide()

        @onAction()

    hide: ->
        @dataTable.fnSetColumnVis(@columnIndex, false)

# Export
window.Digilys ?= {}
window.Digilys.ColumnMenu = ColumnMenu
