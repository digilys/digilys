###
Sets up a listener on a list where there are checkbox toggles.
The listener performs a remote call to different urls depending on
the state of the toggle
###
class RemoteToggleList
    constructor: (@list, @param) ->
        @list = $(@list)

        self = this

        @list.on "change", ":checkbox", -> self.update($(this))

    update: (checkbox) ->
        params         = {}
        params[@param] = [checkbox.val()]

        if checkbox.is(":checked")
            url           = @list.data("on-url")
            params._method = "put"
        else
            url           = @list.data("off-url")
            params._method = "delete"

        $.post(url, params)

# Export
window.Digilys ?= {}
window.Digilys.RemoteToggleList = RemoteToggleList
