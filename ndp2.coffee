# NodeJS design patterns 2 ed.

log = console.log.bind(console)
fs = require 'fs'
numFile = './numbers.txt'
strFile = './string.txt'
EventEmmiter = require 'events'
server = require('http').createServer()
pry = require 'pry'
assert = require 'assert'

after = (ms, fn) -> setTimeout(fn, ms)