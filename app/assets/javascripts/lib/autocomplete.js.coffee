###
Creates a generic autocomplete using select2
###

class Autocomplete
    constructor: (@elem, @query_keys...) ->
        @query_keys = ["name_cont"] if @query_keys.length <= 0

        @elem.each (i, elem) =>
            elem = $(elem)

            elem.select2
                width:              "off"
                multiple:           elem.data("multiple")
                minimumInputLength: 0
                placeholder:        elem.data("placeholder")
                formatResult:       => @formatResult.apply(this, arguments)
                ajax:
                    url:            elem.data("url")
                    results:        => @parseResults.apply(this, arguments)
                    data:           => @requestData.apply(this, arguments)

            if data = elem.data("data")
                elem.select2 "data", data

            if elem.data("autofocus")
                elem.select2 "open"

    requestData: (term, page) ->
        data =
            q: {}
            page: page

        for key in @query_keys
            data.q[key] = term

        return data

    parseResults: (data, page) ->
        results: data.results
        more:    data.more

    formatResult: $.fn.select2.defaults.formatResult

# Export
window.Digilys ?= {}
window.Digilys.Autocomplete = Autocomplete


###
Creates an autocomplete for things that return a name and a description
as two separate fields. The query defaults to name_or_description_cont,
and the result is formatted with a small tag around the description
###
class DescriptionAutocomplete extends Autocomplete
    constructor: (elem, query_keys...) ->
        query_keys = ["name_or_description_cont"] if query_keys.length <= 0
        super elem, query_keys...

    formatResult: (result, container, query, escapeMarkup) ->
        nameMarkup = []
        window.Select2.util.markMatch(result.name || "", query.term, nameMarkup, escapeMarkup)

        descriptionMarkup = []
        window.Select2.util.markMatch(result.description || "", query.term, descriptionMarkup, escapeMarkup)

        return nameMarkup.join("") + '<small>' + descriptionMarkup.join("") + "</small>"

window.Digilys.DescriptionAutocomplete = DescriptionAutocomplete


###
Creates an autocomplete for selecting groups based on their names
and their parents' names
###
class GroupAutocomplete extends Autocomplete
    requestData: (term, page) ->
        terms = term.split(/\s*,\s*/)
        q = { name_cont: terms.shift() }

        for t, i in terms
            q["parent_#{i}_name_cont"] = t

        return { q: q, page: page }

window.Digilys.GroupAutocomplete = GroupAutocomplete


###
Creates an autocomplete for selecting both students and groups
###
class StudentGroupAutocomplete extends Autocomplete
    requestData: (term, page) ->
        sq:
            first_name_or_last_name_cont: term
        gq:
            name_cont: term
        page: page

window.Digilys.StudentGroupAutocomplete = StudentGroupAutocomplete
