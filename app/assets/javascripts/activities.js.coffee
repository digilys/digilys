window.Digilys ?= {}
window.Digilys.Autocomplete ?= {}

window.Digilys.Autocomplete.activityStudentsGroups = (field) ->
    window.Digilys.autocomplete(
        field,
        data: (term, page) ->
            {
                sq: { first_name_or_last_name_cont: term }
                gq: { name_cont: term }
                page: page
            }
    )

$ ->
    $(".activity-students-autocomplete-field").each ->
        window.Digilys.Autocomplete.activityStudentsGroups(this)
