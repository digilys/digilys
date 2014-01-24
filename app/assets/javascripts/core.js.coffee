$ ->
    $("[autofocus]:not(:focus)").eq(0).focus()
    $(":input[placeholder]").placeholder()

    $("#eula-modal").modal("show")

    $("input.datepicker").datepicker(
        language:  "sv"
        format:    "yyyy-mm-dd"
        weekStart: 1
        autoclose: true
    )

    $("input.tag-field").each ->
        new Digilys.TagField($(this))

    $("form:not(.prevent-navigation-confirmation)").each ->
        new Digilys.WarnableForm($(this), Digilys.navigationConfirmation)
