# Use the JsonGem as the Rails JSON backend. Yajl is used by default if required, but
# JsonGem was used from the start, so in order to prevent any problems with differences
# in encoding/decoding, we use JsonGem.

MultiJson.use(:json_gem)
