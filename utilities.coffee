urlParse = require('url').parse
slug = require('slug')
path = require('path')
log = console.log.bind(console)

module.exports.urlToFilename = urlToFilename = (url) ->
  parsedUrl = urlParse(url)
  log parsedUrl
  urlPath = parsedUrl.path.split('/')
    .filter = (component) -> component isnt ''
    .map = (component) -> slug(component)
    .join('/')
  filename = path.join(parsedUrl.hostname, urlPath)
  if not path.extname(filename).match(/htm/)
    filename += '.html'
  filename
