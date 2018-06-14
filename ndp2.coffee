# NodeJS design patterns 2 ed.

log = console.log.bind(console)
fs = require 'fs'
numFile = './fileA.txt'
{EventEmitter} = require 'events'
server = require('http').createServer()
pry = require 'pry'
assert = require 'assert'
logger = require './logger.coffee'

after = (ms, fn) -> setTimeout(fn, ms)

# Map

test = new Map
test.set 'tomek', 'boss'
log test.has 'tomek'
log test.size

# Sets = lists with unique values

s = new Set [0,1,2,3,4]
log s
s.add 5
s.delete 3
log s

# WeakMap and WeakSet - no iteration + garbage collection

obj = {}
wm = new WeakMap
wm.set obj, {'kati': 'szefowa'}
log wm.get obj
log obj

# I/O - actively poll the resource within a loop until some actual data is returned - this is called busy-waiting


# resources = [socketA, socketB, pipeA];
# while(!resources.isEmpty()) {
#   for(i = 0; i < resources.length; i++) {
#     resource = resources[i];
#      //try to read
#     let data = resource.read();
#     if(data === NO_DATA_AVAILABLE)
#       //there is no data to read at the moment
#       continue;
#     if(data === RESOURCE_CLOSED)
#       //the resource was closed, remove it from the list
#       resources.remove(i);
#     else
#       //some data was received, process it
#       consumeData(data);
#   }
# }


# synchronous event demultiplexer or event notification interface


# socketC, pipeB;
# watchedList.add(socketC, FOR_READ); //[1]
# watchedList.add(pipeB, FOR_READ);
# while(events = demultiplexer.watch(watchedList)) { //[2]
#   //event loop
#   foreach(event in events) { //[3]
#     //This read will never block and will always return data
#     data = event.resource.read();
#     if(data === RESOURCE_CLOSED)
#       //the resource was closed, remove it from the watched list
#       demultiplexer.unwatch(event.resource);
#     else
#       //some actual data was received, process it
#       consumeData(data);
#   }
# }

# EVENT LOOP

# These are the important steps of the preceding pseudocode:
#   1. The resources are added to a data structure, associating each one of them with a
#   specific operation, in our example, read.
#   2. The event notifier is set up with the group of resources to be watched. This call is
#   synchronous and blocks until any of the watched resources are ready for read.
#   When this occurs, the event demultiplexer returns from the call and a new set of
#   events is available to be processed.
#   3. Each event returned by the event demultiplexer is processed. At this point, the
#   resource associated with each event is guaranteed to be ready to read and to not
#   block during the operation. When all the events are processed, the flow will block
#   again on the event demultiplexer until new events are again available to be
#   processed. This is called the event loop.


# CALLBACKS

add = (a, b) -> log a + b
add(4,4)

# equivalent continuation-passing style

result = -> log "Result: #{result}"

addc = (a, b, callback) ->
  callback(a + b)

log 'before'
addc(1, 3, result)
log 'after'

addAsync = (a, b, cb) ->
  after 150, () => cb(a + b)

log 'before'
addAsync(1, 3, result)
log 'after'

r = [2, 4, 6].map (element) -> element - 1
log r

# sync and async

# mix = bad
cache = {}
inconsistentRead1 = (filename, callback) ->
  if cache[filename]
    # invoked synchronously
    callback cache[filename]
  else
    # asynchronous function
    fs.readFile filename, 'utf8', (err, data) ->
      cache[filename] = data
      callback data

# sync
inconsistentRead2 = (filename, callback) ->
  if cache[filename]
    return cache[filename]
  else
    cache[filename] = fs.readFileSync(filename, 'utf8')
    return cache[filename]

#async - deffered
inconsistentRead3 = (filename, callback) ->
  if cache[filename]
    process.nextTick () -> callback cache[filename]
  else
    fs.readFile filename, 'utf8', (err, data) ->
      cache[filename] = data
      callback data

# process.nextTick() defers the execution of a function until the next pass of the event loop
# process.nextTick() run before any other I/O event is fired, while with
# setImmediate(), the execution is queued behind any I/O event that is already in the queue

# pattern:

readJSON = (filename, callback) ->
  fs.readFile filename, 'utf8', (err, data) ->
    if err
      callback err
    try
      parsed = JSON.parse data
    catch err
      callback err
    callback null, parsed


# module
module = do ->
  privateFoo = () ->
  privateBar = []
  exported =
    publicFoo: () ->
    publicBar: () ->
  exported

log module

# using an exported function as a namespace
logger.info 'This is an informational message'
logger.verbose 'This is a verbose message'
logger()

# classLoggr = new logger
# classLoggr.info2('asdf')


# require

required = (moduleName) ->
  id = required.resolve(moduleName)
  return required.cache[id].exports if required.cache[id]
  module =
    exports: {}
    id: id
  required.cache[id] = module
  loadModule(id, module, required)
  module.exports
required.cache = {}
required.resolve = (moduleName) -> log moduleName

# add a new function to another module
require('./logger.coffee').customMessage = -> log 'this is a new functionality'
logger.customMessage()


# The observer pattern p.83 ****************************************************************************************

# pattern is already built into the core - available through the EventEmitter class. The
# EventEmitter class allows us to register one or more functions as listeners
# usage:
  # EventEmitter = require('events').EventEmitter
  # eeInstance = new EventEmitter()
# methods:

  # - on(event, listener): This method allows you to register a new listener (a function) for the given event type (a string)
  # - once(event, listener): This method registers a new listener, which is then removed after the event is emitted for the first time
  # - emit(event, [arg1], [...]): This method produces a new event and provides additional arguments to be passed to the listeners
  # - removeListener(event, listener): This method removes a listener for the specified event type


findPattern = (files, regex) ->
  emiter = new EventEmitter
  files.forEach (file) ->
    fs.readFile file, 'utf8', (err, data) ->
      if err
        emiter.emit 'error', err
      emiter.emit('fileread', file)
      if match = data.match(regex)
        log 'emit'
        # match.forEach (elem) -> emiter.emit('found', file, elem)
  emiter

findPattern ['fileA.txt'], /hello \w+/g
  .on 'fileread', (file) -> log "#{file} was read"
  .on 'error', (err) -> log err.message
  .on 'found', (file, match) -> log "#{match} foound in file #{file}"

# FindPattern prototype that we defined extends EventEmitter using the inherits() function provided by the core module util

class FindPatternClass extends EventEmitter
  constructor: (@regex) ->
    super()
    @files = []
  addFile: (file) ->
    @files.push file
    return @
  find: ->
    @files.forEach (file) ->
      fs.readFile file, 'utf8', (err, data) ->
        if err
          @emit 'error', err
        # @emit('fileread', file)
        # if match = data.match(@regex)
        #   log 'emit'
        #   match.forEach (elem) -> @emit('found', file, elem)
    return @

findPatternObject = new FindPatternClass(/hello \w+/)

findPatternObject
  .addFile('fileA.txt')
  .find()
  .on 'found', (file, match) -> log "#{match} in file #{file}"
  .on 'error', (err) -> log err.message


# Synchronous and asynchronous events - the way listeners can be registered

































