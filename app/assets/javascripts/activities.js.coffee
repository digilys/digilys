window.Digilys ?= {}
window.Digilys.Autocomplete ?= {}

window.Digilys.Autocomplete.activityStudentsGroups = (field) ->
    $field = $(field)

    $field.select2(
        multiple: $field.data("multiple"),
        minimumInputLength: 3
        placeholder: $field.data("placeholder")
        ajax:
            url: $field.data("url")
            results: (data, page) ->
                { results: data }
            data: (term, page) ->
                {
                    sq: { first_name_or_last_name_cont: term },
                    gq: { name_cont: term },
                    page: page }
    )

    data = $field.data("data")

    if data
        $field.select2("data", data)


    if $field.data("autofocus")
        $field.select2("open")

$ ->
    $(".activity-students-autocomplete-field").each ->
        window.Digilys.Autocomplete.activityStudentsGroups(this)
