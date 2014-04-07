window.onerror = (message, url, line) ->
    try
        $.post(
            "/error/log",
            { message: message, url: url, line: line }
        )
        return false
    catch error
        return false
