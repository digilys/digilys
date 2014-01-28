###
Utility methods for datatables
###

datatables = {}

# Callback for saving data table state, with throttling functionality
datatables.stateTimeoutId = null
datatables.saveState = (state, url) ->

    if datatables.stateTimeoutId
        window.clearTimeout(datatables.stateTimeoutId)

    callback = ->
        $.post(url, { _method: "PUT", state: JSON.stringify(state) })

    datatables.stateTimeoutId = window.setTimeout(callback, 1000)

# Processes a datatables state into a state that is eligible
# for saving.
#
# - Replaces column indexes in the order array with DOM ids
# - Changes the visual columns array to include only the DOM ids of the hidden columns
#
# The expected arguments are the state that's to be saved, and
# the column definitions from dataTables (fnSettings().aoColumns)
datatables.processStateForSaving = (state, columns) ->

    return state unless state

    if state.ColReorder
        state.ColReorder = []
        state.ColReorder.push(col.nTh.id) for col in columns

    if state.abVisCols
        hidden = []

        hidden.push(col.nTh.id) for col in columns when !state.abVisCols[col._ColReorder_iOrigCol]

        state.abVisCols = hidden

    return state

# Converts DOM ids to column indexes
datatables.processStateForLoading = (state, domIds) ->
    return state unless state

    if state.ColReorder && /^datatable-column/.test(state.ColReorder[0])
        colReorder = []

        # Replace DOM ids with the columns index in the DOM (before the reorder)
        for id in state.ColReorder
            idx = domIds.indexOf(id)

            # Ignore columns missing in the DOM
            if idx >= 0
                colReorder.push(idx)


        # Handle any columns that exists in the DOM but not in the state
        # by adding them last
        colReorder.push(idx) for idx in [0..domIds.length-1] when colReorder.indexOf(idx) < 0

        state.ColReorder = colReorder

    if state.abVisCols && (state.abVisCols.length <= 0 || /^datatable-column/.test(state.abVisCols[0]))
        columns = []

        # Make all columns shown by default
        columns.push(true) for id in domIds

        # Hide all columns matching the ids in the array of hidden column ids
        for id in state.abVisCols
            idx = domIds.indexOf(id)

            if idx >= 0
                columns[idx] = false

        state.abVisCols = columns

    return state

# Export
window.Digilys ?= {}
window.Digilys.datatables = datatables
