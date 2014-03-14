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
    $("input.editable-select").each ->
        new Digilys.EditableSelect($(this))

    $("form:not(.prevent-navigation-confirmation)").each ->
        new Digilys.WarnableForm($(this), Digilys.navigationConfirmation)

    $(".import-confirmation-list").tooltip(selector: "[title]")

    $("form.masked-on-submit").on "submit", -> new Digilys.LoadMask($(this))
