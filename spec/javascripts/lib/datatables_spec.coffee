describe "Digilys.datatables", ->
    prefixed = (array) ->
        "datatable-column-#{str}" for str in array

    describe "convertColumnIndexesToIDs", ->
        convertColumnIndexesToIDs = window.Digilys.datatables.convertColumnIndexesToIDs

        it "converts ColReorder indexes to IDs", ->
            expect(
                convertColumnIndexesToIDs(
                    { "ColReorder": [ 2, 1, 0 ] },
                    [ "foo", "bar", "baz" ]
                )
            ).toEqual { "ColReorder": [ "foo", "bar", "baz" ] }

    describe "convertIDsToColumnIndexes", ->
        convertIDsToColumnIndexes = window.Digilys.datatables.convertIDsToColumnIndexes

        it "converts ColReorder IDs to indexes", ->
            expect(
                convertIDsToColumnIndexes(
                    { "ColReorder": prefixed([ "foo", "bar", "baz"]) },
                    prefixed([ "baz", "foo", "bar" ])
                )
            ).toEqual { "ColReorder": [ 1, 2, 0 ] }

        it "handles missing columns", ->
            expect(
                convertIDsToColumnIndexes(
                    { "ColReorder": prefixed([ "foo", "apa", "bar", "baz"]) },
                    prefixed([ "baz", "foo", "bar" ])
                )
            ).toEqual { "ColReorder": [ 1, 2, 0 ] }

        it "handles extra columns", ->
            expect(
                convertIDsToColumnIndexes(
                    { "ColReorder": prefixed([ "foo", "bar", "baz"]) },
                    prefixed([ "baz", "apa", "foo", "bar" ])
                )
            ).toEqual { "ColReorder": [ 2, 3, 0, 1 ] }

        it "does nothing if there are no DOM id:s to convert", ->
            expect(
                convertIDsToColumnIndexes(
                    { "ColReorder": [ 1, 3, 2] },
                    prefixed([ "foo", "bar", "baz" ])
                )
            ).toEqual { "ColReorder": [ 1, 3, 2 ] }
