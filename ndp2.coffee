# NodeJS design patterns 2 ed.
# code:
# https://github.com/PacktPublishing/Node.js_Design_Patterns_Second_Edition_Code

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
        log "match is an array: "
        log match
        match.forEach (elem) ->
          log file
          log elem
          emiter.emit('found', file, elem)
  emiter

findPattern(['fileA.txt'], /hello \w+/g)
  .on 'fileread', (file) -> log "#{file} was read"
  .on 'error', (err) -> log err.message
  .on 'found', (file, match) -> log "#{match} found in file #{file}"

# FindPattern prototype that we defined extends EventEmitter using the inherits() function provided by the core module util

class FindPatternClass extends EventEmitter
  constructor: (regex) ->
    super()
    @regex = regex
    @files = []
  addFile: (file) ->
    @files.push file
    return @
  find: ->
    @files.forEach (file) ->
      fs.readFile file, 'utf8', (err, data) ->
        @emit 'error', err if err
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


# Synchronous and asynchronous events - the way listeners can be registered *************   web spider

mkdirp = require 'mkdirp'
path = require 'path'
request = require 'request'
utilities = require './utilities.js'

# writes a given string to a file can be easily factored out
fileSave = (filename, content, callback) ->
  mkdirp path.dirname(filename), (err) ->
    if err then callback(err)
    fs.writeFile filename, content, callback
# downloads the URL into the given file
fileDownload = (url, filename, callback) ->
  log "Downloading #{url}"
  request url, (err, response, body) ->
    callback(err) if err
    fileSave filename, body, (err) ->
      if err then callback(err)
      log "Downloaded and saved #{filename}"
      callback(null, body)


spider1 = (url, cb) ->
  log url
  filename = utilities.urlToFilename(url)
  fs.exists filename, (exists) ->
    if not exists
      log "Downloading #{url}"
      request url, (err, response, body) ->
        if err then cb(err)
        else
          mkdirp path.dirname(filename), (err) ->
          if err then cb(err)
          else
            fs.writeFile filename, body, (err) ->
              if err then cb(err)
              else
                cb null, filename, true
    else
      cb null, filename, false


spider2 = (url, cb) ->
  filename = utilities.urlToFilename(url)
  fs.exists filename, (exists) ->
    cb(null, filename, false) if exists
    fileDownload url, filename, (err) ->
      cb(err) if err
      cb null, filename, true

# spider2 'https://www.ultimatum.group/ultimatum.html', (err, filename, downloaded) ->
#   if err then log err
#   else if downloaded
#     log "complete the download #{filename}"
#   else
#     log "#{filename} was already downloaded"


# Sequential execution   **************************************************************

task1 = (callback) ->
  asyncOperation = -> task2(callback)

task2 = (callback) ->
  asyncOperation = -> task3(callback)

task3 = (callback) ->
  asyncOperation = -> callback()

# using a sequential asynchronous iteration algorithm
spiderLinks = (currentUrl, body, nesting, callback) ->
  process.nextTick(callback) if nesting is 0
  links = utilities.getPageLinks(currentUrl, body)
  iterate = (index) ->
    return callback() if index is links.length
    spider links[index], nesting - 1, (err) ->
      callback(err) if err
      iterate(index + 1)
  iterate(0)

spiderLinksParallel = (currentUrl, body, nesting, callback) ->
  process.nextTick(callback) if nesting is 0
  links = utilities.getPageLinks(currentUrl, body)
  process.nextTick(callback) if links.length is 0
  completed = 0
  hasErrors = false
  # trick to make our application wait for all the tasks to complete is to provide the spider() function with a special callback done().
  done = (err) ->
    if err
      hasErrors = true
      callback(err)
    if ++completed is links.length and not hasErrors then callback()
  links.forEach (link) -> # iterating over the links array and starting each task without waiting for the previous one to finish
    spider link, nesting - 1, done

# QUEUE   ******************************************************************************

class TaskQueue
  constructor: (@concurrency) ->
    @running = 0
    @queue = []

  pushTask = (task) ->
    @queue.push(task)
    @next()

  next = ->
    while @running < @concurrency and @queue.length
      task = @queue.shift()
      task () ->
        @running--
        @next()
      @running++

downloadQueue = new TaskQueue(2)

spiderLinksQueue = (currentUrl, nesting, body, callback) ->
  return process.nextTick(callback) if nesting is 0
  links = utilities.getPageLinks(currentUrl, body)
  return process.nextTick(callback) if links.length is 0
  completed = 0
  hasErrors = false
  links.forEach (link) ->
    downloadQueue.pushTask (done) ->
      spider link, nesting - 1, (err) ->
        if err
          hasErrors = true
          callback(err)
        if ++completed is links.length and not hasErrors
          callback()
        done()


# spider adjusted:
spidering = new Map
spider = (url, nesting, callback) ->
  if spidering.has(url)
    process.nextTick(callback)
  spidering.set url, true
  log 'this is spidering: '
  log spidering
  filename = utilities.urlToFilename(url)
  fs.readFile filename, 'utf8', (err, body) ->
    if err
      callback(err) if err.code isnt 'ENOENT'
      fileDownload url, filename, (err, body) ->
        callback(err) if err
        spiderLinksQueue(url, nesting, body, callback)
    spiderLinksQueue(url, nesting, body, callback)


# pattern can be adapted to any situation where we have the need to iterate asynchronously
# in sequence over the elements of a collection or in general over a list of tasks
# general version:
tasks = ['https://www.ultimatum.group', 'https://www.ultimatum.group/ultimatum.html']
finish = -> log 'iteration completed'
iteration = (index) ->
  finish() if index is tasks.length
  task = tasks[index]
  tasker = ->
    log task
    iteration(index + 1)
iteration(0)

# Parallel execution   ****************************************************************
# general version:
completed_ = 0
tasks.forEach (tazk) ->
  tazk = () -> finish() if ++completed is tasks.length

# `
# let complet = 0;
# tasks.forEach(task => {
#   task(() => {
#     if(++complet === tasks.length) {
#       finish();
#     }
#   });
# });
# `

# pattern to execute a set of given tasks in parallel with limited concurrency.
# general version:
concure = 2
running = 0
compl = 0
ind = 0
next = ->
  while running < concure and ind < tasks.length
    task = tasks[index++]
    do
      if compl is tasks.length
        finish()
      compl++
      running--
      next()
    running++
  next()


# PROMISE   ****************************************************************************************************************

# To receive the fulfillment value or the error (reason) associated with the rejection, we use the then() method of the promise
# promise.then([onFulfilled], [onRejected])
# onFulfilled() is a function that will eventually receive the fulfillment value
# onRejected() is another function that will receive the reason for the rejection

# typical CPS - continous passing style:
#
# asyncOperation(arg, (err, result) => {
#   if(err) {
#     // handle error
#   }
#   // do stuff with result
#   });

# promise way:

# asyncOperation(arg)
#   .then(result => {
#     //do stuff with result
#   }, err => {
#     //handle error
#   });

# if we don't specify an onFulfilled() or onRejected() handler, the fulfillment value or rejection reasons are
# automatically forwarded to the next promise in the chain.

# asyncOperation(arg)
#   .then(result1 => {
#     //returns another promise
#     return asyncOperation(arg2);
#   })
#   .then(result2 => {
#     //returns a value
#     return 'done';
#   })
#   .then(undefined, err => {
#     //any error in the chain is caught here
#   });




































