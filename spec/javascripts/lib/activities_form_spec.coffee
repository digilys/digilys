describe "Digilys.ActivitiesForm", ->

    activitiesForm = null
    form           = null
    container      = null
    trigger        = null
    template       = null

    beforeEach ->
        form = $("<form/>")

        container = $('<div class="activities" data-tinymce="window.zomg = \'lol\';"/>')

        template = $('<div class="activity"/>')
        template.append $('<input/>')
            .attr("id", "meeting_activities_attributes_0_start_date")
            .attr("name", "meeting[activities_attributes][0][start_date]")

        container.append(template)

        trigger = $('<a class="trigger"/>')
        container.append(trigger)

        form.append(container)

        expect(window.zomg).toBeUndefined()

        activitiesForm = new Digilys.ActivitiesForm
            form:      form
            container: ".activities"
            activity:  ".activity"
            trigger:   ".trigger"


    afterEach ->
        delete window.zomg

    describe "constructor", ->
        it "correctly assigns the arguments", ->
            expect(activitiesForm.form).toBe        form
            expect(activitiesForm.container).toBe   container
            expect(activitiesForm.activity).toBe    ".activity"
            expect(activitiesForm.tinymceCode).toBe "window.zomg = 'lol';"

        it "builds a template, replacing indexes in attributes with a placeholder", ->
            tpl = $(activitiesForm.template)
            expect(tpl).toHaveClass "activity"
            expect(tpl.children()).toHaveLength(1)
            
            input = tpl.children(":first")
            expect(input).toHaveAttr "id",   "meeting_activities_attributes_{{idx}}_start_date"
            expect(input).toHaveAttr "name", "meeting[activities_attributes][{{idx}}][start_date]"
            
        it "binds a click listener on the container, with the trigger as a filter", ->
            spyOn(activitiesForm, "addFields")
            trigger.trigger("click")
            template.trigger("click")
            expect(activitiesForm.addFields.calls.length).toEqual 1


    describe ".addFields()", ->
        beforeEach ->
            form.append($('<div class="tinymce"/>'))

            template.append($('<input class="textfield" value="zomg" type="text"/>'))
            template.append($('<textarea>zomg</textarea>'))
            template.append($('<div class="select2-container"/>'))

            template.append($('<input class="activity-students-autocomplete-field" data-data="zomg"/>'))
            template.append($('<input class="user-autocomplete-field" data-data="zomg"/>'))

            template.append($('<input class="datepicker"/>'))

            spyOn(Digilys, "StudentGroupAutocomplete").andReturn(null)
            spyOn(Digilys, "Autocomplete").andReturn(null)

            activitiesForm = new Digilys.ActivitiesForm
                form:      form
                container: ".activities"
                activity:  ".activity"
                trigger:   ".trigger"

            activitiesForm.addFields()

        it "removes all tinymce classes from all elements in the form", ->
            expect(form.find(".tinymce")).toHaveLength(0)

        it "adds the fields after the last of the activity containers, with the proper index", ->
            expect(container.children(".activity")).toHaveLength 2

            input = container.find(".activity:last input:first")
            expect(input).toHaveAttr "id",   "meeting_activities_attributes_1_start_date"
            expect(input).toHaveAttr "name", "meeting[activities_attributes][1][start_date]"

        it "clears all text fields and text areas", ->
            expect(container.find(".activity:last .textfield")).toHaveValue("")
            expect(container.find(".activity:last textarea")).toHaveValue("")

        it "removes all select2 containers", ->
            expect(container.find(".activity:last .select2-container")).toHaveLength(0)

        it "initializes student and group autocomplete fields", ->
            students = container.find(".activity:last input.activity-students-autocomplete-field")
            expect(students).toHaveData("data", null)
            expect(students).toHaveValue("")
            expect(Digilys.StudentGroupAutocomplete).toHaveBeenCalled()

        it "initializes user autocomplete fields", ->
            users = container.find(".activity:last input.user-autocomplete-field")
            expect(users).toHaveData("data", null)
            expect(users).toHaveValue("")
            expect(Digilys.Autocomplete).toHaveBeenCalledWith(jasmine.any(Object), "name_or_email_cont")

        it "initializes datepickers", ->
            expect(container.find(".activity:last .datepicker")).toHaveData("datepicker")

        it "evaluates the tinymce code", ->
            expect(window.zomg).toEqual("lol")
