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

# Converts column indexes in a datatable state to DOM ids for better
# persistence and handling when the underlying DOM order changes
datatables.convertColumnIndexesToIDs = (state, domIds) ->

    if state.ColReorder
        # Just replace the column order with the DOM ids, since the DOM ids are
        # sorted by dom order
        state.ColReorder = domIds

    return state

# Converts DOM ids to column indexes
datatables.convertIDsToColumnIndexes = (state, domIds) ->
    # Don't process non-converted states
    return state if !state || !state.ColReorder || !/^datatable-column/.test(state.ColReorder[0])

    if state.ColReorder
        colReorder = []

        # Replace DOM ids with the columns index in the DOM (before the reorder)
        for id in state.ColReorder
            idx = domIds.indexOf(id)

            # Ignore columns missing in the DOM
            if idx >= 0
                colReorder.push(idx)


        # Handle any columns that exists in the DOM but not in the state
        # by adding them last
        for idx in [0..domIds.length-1]
            if colReorder.indexOf(idx) < 0
                colReorder.push(idx)

        state.ColReorder = colReorder

    return state

# Export
window.Digilys ?= {}
window.Digilys.datatables = datatables
