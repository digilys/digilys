$ ->
    selector = $("#table-state-selector")
    if selector.length > 0
        new Digilys.TableStateManager(
            $("#table-states"),
            selector,
            $("#table-state-name"),
            $("#save-table-state")
        )
