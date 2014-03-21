###
Simple utilities
###
#
window.utils ?= {}

###
Throttle function calls that might be called frequently
and where only the last execution is relevant.
###

throttles = {}

throttle = (delay, id, callback) ->
    window.clearTimeout(throttles[id]) if throttles[id]
    throttles[id] = window.setTimeout(callback, delay)

window.utils.throttle = throttle
