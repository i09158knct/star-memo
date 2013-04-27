Vow     = require 'vow'
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

  repoFullNames = stars.map (star) ->
    star.querySelector('h3').textContent
  dateTimes = stars.map (star) ->
    star.querySelector('.sort-info time').getAttribute('datetime')

  if repoFullNames.length == 0
    console.log document.location.href, document.innerHTML
    throw new Error 'empty'

  table = {}
  for i in [0..(repoFullNames.length - 1)]
    table[repoFullNames[i]] = dateTimes[i]

  return table



generateTimesTable = (browser, url) ->
  generating = Vow.promise()
  browser.visit(url).then -> generating.sync Vow.invoke ->
    return table = getTimesTable browser.document

  return generating


generateAllTimesTable = (browserAlreadyLoggedIn, urls) ->
  generatingList = urls.map -> Vow.promise()
  cookies = browserAlreadyLoggedIn.saveCookies()

  delayLoading = (current=0) ->
    return if current == urls.length
    browser = createBrowser()
    browser.loadCookies cookies

    url = urls[current]
    generating = generatingList[current]

    # try upto 3 times
    generating.sync [1..3].reduce (preTrying) ->
      preTrying.fail (reason) ->
        generateTimesTable browser, url
    , Vow.reject()

    # if shorten this interval, behavior is going to be unstable
    setTimeout delayLoading.bind(null, current + 1), 2000

  delayLoading()

  return Vow.all(generatingList).then (tables) ->
    mergedTable = {}
    for table in tables
      for repoFullName, dateTime of table
        mergedTable[repoFullName] = dateTime

    return mergedTable



loadAll = (userName, password) ->
  loadingAll = Vow.promise()
  browser = createBrowser()
  browser.visit(URL.LOGIN).then(->
    browser
      .fill('.auth-form-body #login_field', userName)
      .fill('.auth-form-body #password'   , password)
      .pressButton('.auth-form-body input[type=submit]')
  )

  .then(->
    browser.visit(URL.STARS)
  )

  .then(->
    urls = getAllStarPageUrls browser.document
    generatingAll = generateAllTimesTable browser, urls
    loadingAll.sync generatingAll
  )

  .done()
  return loadingAll



module.exports = loadAll
if require.main == module
  main = (userName, password) ->
    loadingAll = loadAll userName, password
    loadingAll.then((table) ->
      console.log JSON.stringify table, null, 2

    ).done()


  readline = require 'readline'
  rl = readline.createInterface
    input: process.stdin
    output: process.stderr

  asking1 = Vow.promise()
  asking2 = Vow.promise()

  do           -> rl.question 'username: ', asking1.fulfill.bind asking1
  asking1.then -> rl.question 'password: ', asking2.fulfill.bind asking2
  asking2.then -> rl.close()

  Vow.all([asking1, asking2]).spread(main).done()
