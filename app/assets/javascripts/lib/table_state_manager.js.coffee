###
Wires functionality for handling table states: selecting, saving
and deleting.
###

class TableStateManager
    constructor: (@list, @selector, @name, @saveButton) ->

        @selector.on   "change",                     => @select()
        @saveButton.on "click",                      => @save()
        @list.on       "ajax:success", (event, data) => @remove(data.id)


    select: ->
        try
            id = parseInt(@selector.val())
        catch err
            id = 0

        if id > 0
            url = @selector.data("url")
            @selector.attr("disabled", "disabled")
            @redirect(url.replace(":id", id))

        else if id == 0
            url = @selector.data("clear-url")

            @selector.attr("disabled", "disabled")

            # rails.js requires a link element for handleMethod()
            dummy = $("<a/>").attr("href", url)
            dummy.data("method", "delete")
            $.rails.handleMethod(dummy)


    save: ->
        name = $.trim(@name.val())
        return if name == ""

        @saveButton.button("loading")

        url   = @saveButton.data("url")
        state = $(@saveButton.data("table")).data("color-table").getState()

        $.ajax(
            url: url
            method: "POST"
            data:
                table_state:
                    name: name
                    data: JSON.stringify(state)

            success: (data, status, xhr) => @saved(data)
            complete: => @saveButton.button("reset")
        )

    saved: (state) ->
        @name.val("")

        if @selector.find("option[value=#{state.id}]").length <= 0
            $("<option/>")
                .attr("value", state.id)
                .text(state.name)
                .appendTo(@selector)

        if @list.find("tr[data-id=#{state.id}]").length <= 0
            select = $("<a/>")
                .attr("href", state.urls.select)
                .text(state.name)

            destroy = $("<a/>")
                .attr("href", state.urls.default)
                .addClass("btn btn-small btn-danger")
                .attr("data-method", "delete")
                .attr("data-remote", "true")
                .attr("rel", "nofollow")
                .text(@list.data("delete-action-name"))

            $("<tr/>")
                .attr("data-id", state.id)
                .append($("<td/>").append(select))
                .append($("<td/>").append(destroy))
                .appendTo(@list)


    remove: (id) ->
        @list.find("[data-id=#{id}]").remove()
        @selector.find("[value=#{id}]").remove()


    redirect: (href) ->
        window.location.href = href

# Export
window.Digilys ?= {}
window.Digilys.TableStateManager = TableStateManager
