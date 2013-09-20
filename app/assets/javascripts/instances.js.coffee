$ ->
    $("#instance-selector-toggler").one "click", ->
        $toggler = $(this)
        $.get $toggler.attr("href"), (html, textStatus, xhr) ->
            $toggler.siblings(".dropdown-menu").find(".load-indicator").replaceWith(html)
