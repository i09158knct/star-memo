Q       = require 'q'
Browser = require 'zombie'


URL =
  LOGIN: 'https://github.com/login'
  STARS: 'https://github.com/stars'

createBrowser = -> new Browser
  runScripts: false
  loadCSS: false
  # debug: true


getAllStarPageUrls = (document) ->
  [links...] = document.querySelectorAll('.pagination a')
  lastPage = +links[links.length - 2].textContent
  return urls = [1..lastPage].map (page) ->
    URL.STARS + "?direction=desc&page=#{page}&sort=created"


getTimesTable = (document) ->
  [stars...] = document.querySelectorAll('.starred-repo')

  table = stars.reduce (table, star) ->
    fullname = star.querySelector('h3').textContent
    datetime = star.querySelector('.sort-info time').getAttribute('datetime')
    table[fullname] = datetime
    return table
  , {}

  if Object.keys(table).length == 0
    console.log document.location.href, document.innerHTML
    throw new Error 'empty'
  else
    return table


generateTimesTable = (browser, url) ->
  browser.visit(url).then(-> getTimesTable browser.document)


generateAllTimesTable = (browserAlreadyLoggedIn, urls) ->
  deferredGeneratings = urls.map -> Q.defer()
  generatings = deferredGeneratings.map (deferred) -> deferred.promise
  cookies = browserAlreadyLoggedIn.saveCookies()

  do delayLoading = (current=0) ->
    return if current == urls.length
    browser = createBrowser()
    browser.loadCookies cookies

    url = urls[current]
    deferred = deferredGeneratings[current]

    # try upto 3 times
    deferred.resolve [1..3].reduce (preTrying) ->
      preTrying.catch (reason) -> generateTimesTable browser, url
    , Q.reject()

    # if shorten this interval, behavior is going to be unstable
    setTimeout (-> delayLoading(current + 1)), 2000


  return Q.all(generatings).then (tables) ->
    tables.reduce (mergedTable, table) ->
      for fullname, dateTime of table
        mergedTable[fullname] = dateTime
      return mergedTable
    , {}



loadAll = (username, password) ->
  browser = createBrowser()
  browser.visit(URL.LOGIN).then(->
    browser
      .fill('.auth-form-body #login_field', username)
      .fill('.auth-form-body #password'   , password)
      .pressButton('.auth-form-body input[type=submit]')
  )

  .then(->
    browser.visit(URL.STARS)
  )

  .then(->
    urls = getAllStarPageUrls browser.document
    generateAllTimesTable browser, urls
  )



module.exports = loadAll
if require.main == module
  readline = require 'readline'
  rl = readline.createInterface
    input: process.stdin
    output: process.stderr

  deferredAsking = Q.defer()
  rl.question 'username:', (username) ->
    rl.question 'password: ', (password) ->
      rl.close()
      deferredAsking.resolve [username, password]

  deferredAsking.promise.spread(loadAll).done (table) ->
    console.log JSON.stringify table, null, '\t'
