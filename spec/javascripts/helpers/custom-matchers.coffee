Matchers =
    # Verifies the context on which a method has been called
    toHaveBeenCalledOn: (util, customEqualityTesters) ->
        compare: (actual, expected) ->
            result = { pass: false }

            unless jasmine.isSpy(actual)
                throw new Error("Expected a spy, but got #{jasmine.pp(actual)}.")

            unless actual.calls.any()
                result.message = "Expected spy #{actual.and.identity()} to have been called on #{jasmine.pp(expected)} but it was never called."
                return result

            contexts = (call.object for call in actual.calls.all())

            if util.contains(contexts, expected)
                result.message = "Expected spy #{actual.and.identity()} not to have been called on #{jasmine.pp(expected)} but it was."
                result.pass = true
            else
                result.message = "Expected spy #{actual.and.identity()} to have been called on #{jasmine.pp(expected)} but actual context was #{jasmine.pp(contexts)}."

            return result

beforeEach -> jasmine.addMatchers(Matchers)
