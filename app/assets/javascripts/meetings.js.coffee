$ ->
    # Dynamically add more fields for activites when the last fields become used
    $("#meeting-report-form").each ->
        new Digilys.ActivitiesForm
            form:      $(this)
            container: ".activities-fields:first"
            activity:  "fieldset.inputs"
            trigger:   ".add-activity-action"
