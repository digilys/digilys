describe "Digilys.datatables", ->
    prefixed = (array) ->
        "datatable-column-#{str}" for str in array

    aoColumns = (ids...) ->
        columns = []

        columns.push({ _ColReorder_iOrigCol: i, nTh: { id: id }}) for id, i in ids

        return columns

    describe "processStateForSaving", ->
        processStateForSaving = window.Digilys.datatables.processStateForSaving

        it "converts ColReorder indexes to IDs", ->
            expect(
                processStateForSaving(
                    { "ColReorder": [ 2, 1, 0 ] },
                    aoColumns("foo", "bar", "baz"),
                    {}
                )
            ).toEqual { "ColReorder": [ "foo", "bar", "baz" ] }

        it "converts abVisCols to an array with the hidden columns", ->
            expect(
                processStateForSaving(
                    { "abVisCols": [ true, false, true, false ] },
                    aoColumns("foo", "bar", "baz", "apa"),
                    {}
                )
            ).toEqual { "abVisCols": [ "bar", "apa" ] }

        it "handles reordered columns for abVisCols", ->
            columns = aoColumns("foo", "bar", "baz", "apa")
            visible = [ true, false, true, false ]

            columns[1]._ColReorder_iOrigCol = 2
            columns[2]._ColReorder_iOrigCol = 1

            expect(
                processStateForSaving(
                    { "abVisCols": visible },
                    columns,
                    {}
                )
            ).toEqual { "abVisCols": [ "baz", "apa" ]}

        it "adds the number of fixed columns from the options to the state", ->
            expect(
                processStateForSaving(
                    {},
                    [],
                    { fixedColumns: 18 }
                )
            ).toEqual { "fixedColumns": 18 }

    describe "processStateForLoading", ->
        processStateForLoading = window.Digilys.datatables.processStateForLoading

        it "converts ColReorder IDs to indexes", ->
            expect(
                processStateForLoading(
                    { "ColReorder": prefixed([ "foo", "bar", "baz"]) },
                    prefixed([ "baz", "foo", "bar" ])
                )
            ).toEqual { "ColReorder": [ 1, 2, 0 ] }

        it "handles missing ColReorder columns", ->
            expect(
                processStateForLoading(
                    { "ColReorder": prefixed([ "foo", "apa", "bar", "baz"]) },
                    prefixed([ "baz", "foo", "bar" ])
                )
            ).toEqual { "ColReorder": [ 1, 2, 0 ] }

        it "handles extra ColReorder columns", ->
            expect(
                processStateForLoading(
                    { "ColReorder": prefixed([ "foo", "bar", "baz"]) },
                    prefixed([ "baz", "apa", "foo", "bar" ])
                )
            ).toEqual { "ColReorder": [ 2, 3, 0, 1 ] }

        it "does nothing if there are no ColReorder id:s to convert", ->
            expect(
                processStateForLoading(
                    { "ColReorder": [ 1, 3, 2] },
                    prefixed([ "foo", "bar", "baz" ])
                )
            ).toEqual { "ColReorder": [ 1, 3, 2 ] }

        it "converts abVisCols hidden IDs to a visibility array", ->
            expect(
                processStateForLoading(
                    { "abVisCols": prefixed([ "baz" ]) },
                    prefixed([ "foo", "bar", "baz", "apa" ])
                )
            ).toEqual { "abVisCols": [ true, true, false, true ] }

        it "ignores missing abVisCols hidden IDs", ->
            expect(
                processStateForLoading(
                    { "abVisCols": prefixed([ "baz", "zomg" ]) },
                    prefixed([ "foo", "bar", "baz", "apa" ])
                )
            ).toEqual { "abVisCols": [ true, true, false, true ] }

        it "does nothing if there are no abVisCols hidden IDs to convert", ->
            expect(
                processStateForLoading(
                    { "abVisCols": [ true, false, true, true, "error" ] },
                    prefixed([ "foo", "bar", "baz", "apa" ])
                )
            ).toEqual { "abVisCols": [ true, false, true, true, "error" ] }

    describe "columnIndex", ->
        datatable = null
        header    = null

        columnIndex = Digilys.datatables.columnIndex

        beforeEach ->
            header = $("<th/>")

            datatable =
                fnSettings: ->
                    aoColumns: [
                        { nTh: $("<th/>").get(0) },
                        { nTh: header.get(0) },
                        { nTh: $("<th/>").get(0) },
                    ]

        it "returns the column index given a header", ->
            expect(columnIndex(datatable, header)).toEqual 1

        it "returns the column index given an element inside the header", ->
            elem = $("<i/>")
            header.append(elem)
            expect(columnIndex(datatable, elem)).toEqual 1
