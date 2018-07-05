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


utilities = require './utilities'
path = require 'path'
request = utilities.promisify(require('request'))
mkdirp = utilities.promisify(require('mkdirp'))
fs = require 'fs'
readFile = utilities.promisify(fs.readFile)
writeFile = utilities.promisify(fs.writeFile)

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

# general implementation of sequential execution with promises:

# tasks = [ /* ... */ ]
# promise = Promise.resolve()

# tasks.forEach (task) -> 
#   promise = promise.then () -> 
#     task()
# OR:
# promise = tasks.reduce (prev, task) -> 
#   prev.then () -> 
#     task()

# promise.then () -> {
#   # All tasks completed

# promise variable will contain the promise of the last then() invocation in the loop, so it will resolve only 
# when all the promises in the chain have been resolved


spiderLinks = (currentUrl, body, nesting) ->
  promise = Promise.resolve()
  return promise if nesting is 0
  links = utilities.getPageLinks(currentUrl, body)
  links.forEach (link) ->
    promise = promise.then () -> spider(link, nesting - 1)
  promise

spiderLinksParallel = (currentUrl, body, nesting) ->
  Promise.resolve() if nesting is 0
  links = utilities.getPageLinks(currentUrl, body)
  promises = links.map (link) -> spider link, nesting - 1
  Promise.all(promises)

spider = (url, nesting) ->
  filename = utilities.urlToFilename(url)
  log "the file name is: #{filename}"
  readFile(filename).then ((body) ->
    spiderLinks url, body, nesting
    return
  ), (err) ->
    if `err.code != 'ENOENT'`
      throw err
    download(url, filename).then (body) ->
      spiderLinks url, body, nesting
      return

download = (url, filename) ->
  log "downloading #{url}"
  request(url)
  .then (response) ->
    body = response.body
    mkdirp(path.dirname(filename))
  .then () -> writeFile(filename, body)
  .then () ->
    log "downloaded and saved #{url}"
    body

# spider('https://www.ultimatum.group/ultimatum.html', 0)
# .then () -> log 'download completed'
# .catch (err) -> log err


# GENERATORS   ****************************************************************************************************************


fruitGenerator = ->
  yield 'apple'
  yield 'orange'
  return 'watermellon'

newfruitGenerator = fruitGenerator()
log newfruitGenerator.next()
log newfruitGenerator.next()
log newfruitGenerator.next()


# generators as iterators

iteratorGenerator = (arr) ->
  for i in arr 
    yield i

ite = iteratorGenerator(['citron', 'avocado', 'grape'])
currentIte = ite.next()
while not currentIte.done
  log currentIte.value
  currentIte = ite.next()

# pass values back to a generator

twoWayGenerator = -> 
  what = yield null
  log "Hello #{what}"

twoWay = twoWayGenerator()
twoWay.next()
twoWay.next('worlds')

# Asynchronous control flow with generators

asyncFlow = (generatorFn) ->
  callback = (err) ->
    generator.throw(err)
    results = Array.slice.call(arguments, 1)
    generator.next(if results.length > 1 then results else results[0])
  generator = generatorFunction(callback)
  generator.next()

# asyncFlowSelfCopy = (callback) ->
#   fileName = path.basename(__filename)
#   myself = yield fs.readFile(fileName, 'utf8', callback)
#   yield fs.writeFile("clone_of_#{filename}", myself, callback)
#   log 'Clone created'

myself = path.basename(__filename)
log myself


# ASYNC AWAIT   ****************************************************************************************************************


getHTMLpage = (url) ->
  new Promise (res, rej) ->
    request url, (err, response, body) ->
      res body

main = ->
  html = await getHTMLpage('http://google.com')
  # log html

main()


























