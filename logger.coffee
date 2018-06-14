log = console.log.bind(console)

# substack pattern exposes one function
# it exposes only a single functionality, which provides a clear entry point for the module

module.exports = -> log 'module exports function'

module.exports.info = (message) ->
  log "info: #{message}"

module.exports.verbose = (message) ->
  log "verbose: #{message}"


# export of a class:

# class Loggr
#   # constructor: (@name) ->

# Loggr::info2 = (name) ->
#   log "jestem info2: #{name}"

# to use our module as a factory:
# Loggr = (name) ->
#   new Loggr(name) if not @ instanceof Loggr
#   @name = name

# also consider this: new.target property:
# `
# function Logger(name) {
#   if(!new.target) {
#     return new LoggerConstructor(name);
#   }
#   this.name = name;
# }
# `

# module.exports = Loggr

# Exporting a constructor or a class still provides a single entry point for the module, but
# compared to the substack pattern, it exposes a lot more of the module internals; however,
# on the other hand it allows much more power when it comes to extending its functionality


