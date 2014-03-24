###
Functionality for listing and handling authorizations
for a resource
###

class AuthorizationTable
    constructor: (@elem) ->

        self = this

        @url = @elem.data("base-url")

        @elem.on "click", ".remove-action", -> self.remove($(this).closest("[data-id]"))
        @elem.on "authorization-added", (event, userData) => @added(userData)
        @elem.on "change", ":checkbox", -> self.toggleEditor($(this))

    remove: (row) ->
        $.post @url, { user_id: row.data("id"), roles: "reader,editor", _method: "delete" }, => @removed(row)

    removed: (row) ->
        row.remove()

    added: (userData) ->
        if @elem.find("tbody [data-id=#{userData.id}]").length <= 0
            @elem.find("tbody").append(userData["row"])

    toggleEditor: (toggler)->
        params =
            user_id: toggler.closest("[data-id]").data("id")
            roles:   "editor"

        params["_method"] = "delete" unless toggler.is(":checked")

        $.post @url, params

# Export
window.Digilys ?= {}
window.Digilys.AuthorizationTable = AuthorizationTable
