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

            elem.on "select2-open", => @preventOpeningAbove.apply(this, arguments)

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

    enableAutosubmit: (@maskSelector) ->
        @elem.on "change", => @autosubmit.apply(this, arguments)
        @elem.data("preventNavigationConfirmation", true)

    autosubmit: (event) ->
        new Digilys.LoadMask($(@maskSelector))

        form = @elem.parents("form")

        submit = form.find(":submit")
        submit.attr("disabled", "disabled")
        submit.val(submit.data("loading-text"))

        form.submit()

    preventOpeningAbove: ->
        container = @elem.data("select2").container
        containerTop = container.offset().top
        containerBottom = containerTop + container.outerHeight(false)

        win = $(window)
        viewportTop = win.scrollTop()
        viewportBottom = viewportTop + win.height()

        if viewportTop < containerTop && viewportBottom - containerBottom < 220
            $("body").css("padding-bottom", "500px")
            container.get(0).scrollIntoView(true)

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


###
Creates an autocomplete for searching for evaluations, both by
their name or by the suite's name
###

class EvaluationAutocomplete extends Autocomplete
    constructor: (elem) ->
        super elem

    requestData: (term, page) ->
        term = term.replace(/^[\s,]*(.*?)[\s,]*$/, "$1")

        q = {}

        if term.indexOf(",") > -1
            q["name_cont_any"] = term
            q["suite_name_cont_any"] = term
        else
            q["name_or_suite_name_cont"] = term

        return { q: q, page: page }

window.Digilys.EvaluationAutocomplete = EvaluationAutocomplete


###
Creates an autocomplete for adding users to an authorization list
###

class AuthorizationAutocomplete extends Autocomplete
    constructor: (elem, query_keys...) ->
        super elem, query_keys...

        @url  = @elem.data("base-url")
        @list = $(@elem.data("list"))

        @elem.on "change", => @select()

    select: ->
        userId = @elem.val()

        if userId.match(/^\d+$/)
            @elem.data("select2").clear()
            $.post @url, { user_id: userId, roles: "reader" }, (json) => @added(json)

    added: (userData) ->
        @list.trigger("authorization-added", userData)


window.Digilys.AuthorizationAutocomplete = AuthorizationAutocomplete
