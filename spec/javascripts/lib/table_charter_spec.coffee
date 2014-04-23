describe "Digilys.TableCharter", ->
    charter         = null
    selector        = null
    modal           = null
    colorTable      = null
    lineChartDraw   = null
    areaChartDraw   = null
    columnChartDraw = null
    oldGoogle       = null
    addListenerArgs = null

    beforeEach ->
        window.Digilys.i18n =
            stanine:            "stanine-i18n",
            normalDistribution: "normal-distribution-i18n",
            amount:             "amount-i18n",

        oldGoogle = window.google

        lineChartDraw   = jasmine.createSpy("google.LineChart.draw")
        areaChartDraw   = jasmine.createSpy("google.AreaChart.draw")
        columnChartDraw = jasmine.createSpy("google.ColumnChart.draw")

        window.google = visualization:
            LineChart: ->
                this.draw = lineChartDraw
                return this
            AreaChart: ->
                this.draw = areaChartDraw
                return this
            ColumnChart: ->
                this.draw = columnChartDraw
                return this
            events:
                addListener: ->
                    addListenerArgs = arguments

        spyOn(window.google.visualization, "LineChart").and.callThrough()
        spyOn(window.google.visualization, "AreaChart").and.callThrough()
        spyOn(window.google.visualization, "ColumnChart").and.callThrough()

        spyOn(window.google.visualization.events, "addListener").and.callThrough()

        colorTable =
            evaluationColumns: -> "evaluations"
            studentRows: -> "students"

        spyOn(Digilys.TableCharterConverters, "toResultChart").and.returnValue("resultChart")
        spyOn(Digilys.TableCharterConverters, "toColorChart").and.returnValue("colorChart")
        spyOn(Digilys.TableCharterConverters, "toColumnChart").and.returnValue("columnChart")

        selector = $("<select/>")
            .append($("<option/>").attr("value", "").text("default"))
            .append($("<option/>").attr("value", "area").text("area-text"))
            .append($("<option/>").attr("value", "line").text("line-text"))
            .append($("<option/>").attr("value", "column").text("column-text"))
            .attr("data-modal", "#table-charter-modal")
            .data("table", $("<div/>").data("color-table", colorTable))

        modal = $('<div id="table-charter-modal" style="display:none"/>')
            .append('<div class="modal-header"><h3></h3></div>')
            .append('<div class="chart" data-error-message="error-message"/>')
        $("body").append(modal)

        charter = new Digilys.TableCharter(selector)

    afterEach ->
        modal.remove()
        window.google = oldGoogle

    describe "selecting", ->
        it "resets the selector", ->
            selector.val("line").trigger("change")
            expect(selector).toHaveValue("")

        it "does nothing when selecting the default", ->
            selector.val("").trigger("change")
            expect(modal).not.toBeVisible()

        it "does nothing when selecting invalid values", ->
            selector.val("zomg").trigger("change")
            expect(modal).not.toBeVisible()

        it "shows the targeted modal when selecting a valid graph", ->
            selector.val("area").trigger("change")
            expect(modal).toBeVisible()

        it "sets the title of the modal to the selected value", ->
            selector.val("column").trigger("change")
            expect(modal.find(".modal-header h3")).toHaveText("column-text")

        it "sets the height of the chart container to the height of the window minus 150px", ->
            selector.val("line").trigger("change")
            expect(modal.find(".chart").height()).toEqual($(window).height() - 150)

    describe "displaying", ->
        afterEach ->
            expect(google.visualization.events.addListener).toHaveBeenCalled()

        it "displays a line chart when selecting the line chart", ->
            selector.val("line").trigger("change")
            chart = modal.find(".chart")
            expect(google.visualization.LineChart).toHaveBeenCalledWith(chart.get(0))
            expect(Digilys.TableCharterConverters.toResultChart).toHaveBeenCalledWith("evaluations", "students")
            expect(lineChartDraw).toHaveBeenCalledWith(
                "resultChart",
                curveType:        "function"
                width:            chart.width()
                interpolateNulls: true,
                vAxes:            [ format: "#%", maxValue: 1.0 ],
                vAxis:
                    viewWindowMode: "maximized"
            )

        it "displays an area chart when selecting the area chart", ->
            selector.val("area").trigger("change")
            chart = modal.find(".chart")
            expect(google.visualization.AreaChart).toHaveBeenCalledWith(chart.get(0))
            expect(Digilys.TableCharterConverters.toColorChart).toHaveBeenCalledWith("evaluations", "students")
            expect(areaChartDraw).toHaveBeenCalledWith(
                "colorChart",
                width:       chart.width()
                isStacked:   true
                areaOpacity: 1.0
                colors:      [ "#da4f49", "#f4f809", "#5bb75b" ]
                legend:
                    position: "none"
            )

        it "displays a column chart when selecting the column chart", ->
            selector.val("column").trigger("change")
            chart = modal.find(".chart")
            expect(google.visualization.ColumnChart).toHaveBeenCalledWith(chart.get(0))
            expect(Digilys.TableCharterConverters.toColumnChart).toHaveBeenCalledWith("evaluations", "students")
            expect(columnChartDraw).toHaveBeenCalledWith(
                "columnChart",
                width: chart.width(),
                vAxes: [
                    title: "amount-i18n"
                    minValue: 0
                ]
                hAxis:
                    title: "stanine-i18n"
                    gridlines:
                        count: 9
                series:
                    0:
                        type: "line"
            )

    describe "error handling", ->
        it "calls .errorMessage() when receiving an error on the chart", ->
            spyOn(charter, "errorMessage")
            for type in [ "line", "area", "column" ]
                selector.val(type).trigger("change")
                addListenerArgs[2]("error-#{type}")
                expect(charter.errorMessage).toHaveBeenCalledWith("error-#{type}")

        describe ".errorMessage()", ->
            it "adds an error message to the chart container", ->
                charter.errorMessage("error")
                expect(modal.find(".chart .alert.alert-error")).toHaveText("error-message")


describe "Digilys.TableCharterConverters", ->
    C = Digilys.TableCharterConverters

    result    = null
    oldGoogle = null

    beforeEach ->
        oldGoogle = window.google

        window.google = { visualization: {} }
        window.google.visualization.arrayToDataTable = (array) -> array

        spyOn(window.google.visualization, "arrayToDataTable").and.callThrough()

    afterEach ->
        window.google = oldGoogle

    describe ".toResultChart()", ->

        beforeEach ->
            evaluations = [
                { id: "evaluation-1", name: "E 1", field: "e1", maxResult: 4, date: "date-1" },
                { id: "evaluation-2", name: "E 2", field: "e2", maxResult: 8, date: "date-2" }
            ]
            students = [
                { id: 1, name: "foo",  e1: { value: 2 }, e2: { value: 4 } },
                { id: 2, name: "bar",  e1: { value: 3 }, e2: { value: 5 } },
                { id: 3, name: "baz",  e1: {} }
                { id: 4, name: "apa",  e1: { value: 3 } },
                { id: 5, name: "bepa", e2: { value: 4 } },
            ]
            result = C.toResultChart(evaluations, students)

            expect(window.google.visualization.arrayToDataTable).toHaveBeenCalled()

        it "constructs a google chart data table", ->
            expect(result.length).toEqual(3) # title row + 2 evaluation rows

        it "has a title row with the student names, excluding students without any result", ->
            expect(result[0]).toEqual([ "", "foo", "bar", "apa", "bepa" ])

        it "has a data row for each evaluation with the normalized result per student, exluding students without any result", ->
            expect(result[1]).toEqual([ "E 1 (date-1)", 2/4, 3/4, 3/4, undefined ])
            expect(result[2]).toEqual([ "E 2 (date-2)", 4/8, 5/8, undefined, 4/8 ])

    describe ".toColorChart()", ->
        beforeEach ->
            window.Digilys.i18n =
                red:    "red-i18n"
                yellow: "yellow-i18n"
                green:  "green-i18n"

            evaluations = [
                { id: "evaluation-1", name: "E 1", field: "e1", maxResult: 4, date: "date-1" },
                { id: "evaluation-2", name: "E 2", field: "e2", maxResult: 8, date: "date-2" }
            ]

            students = [
                { id: 1, name: "foo", e1: { cssClass: "red" },    e2: { cssClass: "red" } },
                { id: 2, name: "bar", e1: { cssClass: "green" },  e2: { cssClass: "yellow" } },
                { id: 3, name: "baz", e1: { cssClass: "invalid"}, e2: { cssClass: null } },
                { id: 4, name: "zap", e1: {} }
            ]

            result = C.toColorChart(evaluations, students)

            expect(window.google.visualization.arrayToDataTable).toHaveBeenCalled()

        it "constructs a google chart data table", ->
            expect(result.length).toEqual(3) # title row + 2 evaluation rows

        it "has a title row with the colors", ->
            expect(result[0]).toEqual(["", "red-i18n", "yellow-i18n", "green-i18n"])

        it "has a data row for each evaluation with the color distribution for that evaluation", ->
            expect(result[1]).toEqual(["E 1 (date-1)", 1/4 * 100, 0, 1/4 * 100])
            expect(result[2]).toEqual(["E 2 (date-2)", 1/4 * 100, 1/4 * 100, 0])


    describe ".toColumnChart()", ->
        beforeEach ->
            window.Digilys.i18n =
                stanine:            "stanine-i18n",
                normalDistribution: "normal-distribution-i18n",
                amount:             "amount-i18n",

            evaluations = [
                { id: "evaluation-1", name: "E 1", field: "e1", date: "date-1", stanines: true },
                { id: "evaluation-2", name: "E 2", field: "e2", date: "date-2", stanines: true },
                { id: "evaluation-3", name: "E 3", field: "e3", date: "date-3", stanines: false }
            ]

            students = [
                { id: 1, name: "foo",  e1: { stanine: 1 },  e2: { stanine: 7 } },
                { id: 2, name: "bar",  e1: { stanine: 2 },  e2: { stanine: 9 } },
                { id: 3, name: "baz",  e1: { stanine: 11 }, e2: { stanine: null } },
                { id: 4, name: "zap",  e1: {} },
                { id: 5, name: "apa",  e1: { stanine: 5 },  e2: { stanine: 5 } }
                { id: 5, name: "bepa", e1: { stanine: 5 },  e2: { stanine: 5 } }
            ]

            result = C.toColumnChart(evaluations, students)

            expect(window.google.visualization.arrayToDataTable).toHaveBeenCalled()

        it "constructs a google chart data table", ->
            expect(result.length).toEqual(10) # title row + 9 stanines

        it "has a title row with the headers and evaluation names", ->
            expect(result[0]).toEqual(["stanine-i18n", "normal-distribution-i18n", "E 1 (date-1)", "E 2 (date-2)"])

        it "has a row for each stanine value with amounts per evaluation and normal distribution", ->
            expect(result[1]).toEqual([1, 6*0.04, 1, 0])
            expect(result[2]).toEqual([2, 6*0.07, 1, 0])
            expect(result[3]).toEqual([3, 6*0.12, 0, 0])
            expect(result[4]).toEqual([4, 6*0.17, 0, 0])
            expect(result[5]).toEqual([5, 6*0.20, 2, 2])
            expect(result[6]).toEqual([6, 6*0.17, 0, 0])
            expect(result[7]).toEqual([7, 6*0.12, 0, 1])
            expect(result[8]).toEqual([8, 6*0.07, 0, 0])
            expect(result[9]).toEqual([9, 6*0.04, 0, 1])
