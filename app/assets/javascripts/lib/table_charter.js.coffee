###
Displays charts based on what is displayed in a color table.
###

class TableCharter
    constructor: (@selector) ->
        @colorTable = $(@selector.data("table")).data("color-table")
        @modal      = $(@selector.data("modal"))
        @chart      = @modal.find(".chart")

        self = this
        @selector.on "change", ->
            select = $(this)
            value = select.val()
            self.show(value, select.find("[value='#{value}']").first().text())


    show: (type, title) ->
        switch type
            when "line"   then @displayModal title, => @showLineChart()
            when "area"   then @displayModal title, => @showAreaChart()
            when "column" then @displayModal title, => @showColumnChart()

        @selector.val("")

    showLineChart: ->
        chart = new google.visualization.LineChart(@chart.get(0))
        google.visualization.events.addListener chart, "error", (error) => @errorMessage(error)

        chart.draw(
            Converters.toResultChart(@colorTable.evaluationColumns(), @colorTable.studentRows()),
            curveType:        "function"
            width:            @chart.width()
            interpolateNulls: true,
            vAxes:            [ format: "#%", maxValue: 1.0 ]
            vAxis:
                viewWindowMode: "maximized"
        )

    showAreaChart: ->
        chart = new google.visualization.AreaChart(@chart.get(0))
        google.visualization.events.addListener chart, "error", (error) => @errorMessage(error)

        chart.draw(
            Converters.toColorChart(@colorTable.evaluationColumns(), @colorTable.studentRows()),
            width:       @chart.width()
            isStacked:   true
            areaOpacity: 1.0
            colors:      [ "#da4f49", "#f4f809", "#5bb75b" ]
            legend:
                position: "none"
        )

    showColumnChart: ->
        chart = new google.visualization.ColumnChart(@chart.get(0))
        google.visualization.events.addListener chart, "error", (error) => @errorMessage(error)

        students = @colorTable.studentRows()

        chart.draw(
            Converters.toColumnChart(@colorTable.evaluationColumns(), students),
            width: @chart.width()
            vAxes: [
                {
                    title: Digilys.i18n.amount
                    minValue: 0
                }
            ]
            hAxis:
                title: Digilys.i18n.stanine
                gridlines:
                    count: 9
            series:
                0:
                    type: "line"
        )


    displayModal: (title, callback) ->
        @chart.height($(window).height() - 150)
        @modal.find(".modal-header h3").text(title)
        @modal.find(".chart").html("")
        @modal.one("shown", callback)
        @modal.modal("show")


    errorMessage: (error) ->
        @chart.html(
            $("<div/>")
                .addClass("alert alert-error")
                .html(@chart.data("error-message"))
        )

# Export
window.Digilys ?= {}
window.Digilys.TableCharter = TableCharter


###
# Data converters
###

Converters = {}


Converters.toResultChart = (evaluations, students) ->
    array = []
    array[0] = [ "" ]
    array[0].push("#{evaluation.name} (#{evaluation.date})") for evaluation in evaluations

    for student in students
        row = []

        for evaluation in evaluations
            value = student[evaluation.field]

            if value && value.value
                newLength = row.push(value.value / evaluation.maxResult)
            else
                newLength = row.push(undefined)

        # Check if all added values are undefined
        withoutUndefined = (i for i in row when i != undefined)

        if withoutUndefined.length > 0
            row.unshift(student.name)
            array.push(row)

    # Google Chart wants the columns to be the students and the
    # rows to be the evaluations to render a proper graph. We build
    # it the other way around, so now we transpose the array, flipping
    # it to the correct format.
    #
    # The reason for this is that it is much easier to check for
    # students which have only nil results above.
    transposed = []
    width      = array.length
    height     = array[0].length

    for i in [0..(height - 1)]
        transposed[i] = []

        for j in [0..(width - 1)]
            transposed[i][j] = array[j][i]

    return google.visualization.arrayToDataTable(transposed)


Converters.toColorChart = (evaluations, students) ->
    array = []

    array[0] = [ "", Digilys.i18n.red, Digilys.i18n.yellow, Digilys.i18n.green ]

    i = 1
    for evaluation in evaluations
        total = 0
        colors =
            red:    0
            yellow: 0
            green:  0

        for student in students
            total++
            field = student[evaluation.field]

            if field && field.cssClass
                colors[field.cssClass]++

        array[i] = [
            "#{evaluation.name} (#{evaluation.date})",
            colors.red    / total * 100,
            colors.yellow / total * 100,
            colors.green  / total * 100
        ]

        i++

    return google.visualization.arrayToDataTable(array)


Converters.toColumnChart = (evaluations, students) ->
    array = []

    array[0] = [ Digilys.i18n.stanine, Digilys.i18n.normalDistribution ]

    stanines = {}

    n = students.length
    normalDistribution = [ n * 0.04, n * 0.07, n * 0.12, n * 0.17, n * 0.20, n * 0.17, n * 0.12, n * 0.07, n * 0.04 ]

    for evaluation in evaluations when evaluation.stanines
        array[0].push("#{evaluation.name} (#{evaluation.date})")

        stanines[evaluation.id] = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0 }

        for student in students
            value = student[evaluation.field]

            if value && value.stanine
                stanines[evaluation.id][value.stanine]++

    for i in [1..9]
        array[i] = [i, normalDistribution[i-1]]
        array[i].push(stanines[evaluation.id][i]) for evaluation in evaluations when evaluation.stanines

    return google.visualization.arrayToDataTable(array)

window.Digilys.TableCharterConverters = Converters
