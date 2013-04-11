Vow     = require 'vow'
request = require 'request'



loadOne = (url) ->
  loadingOne = Vow.promise()
  request url, (err, res, body) -> loadingOne.sync Vow.invoke ->
    if err?
      throw err
    if res.statusCode != 200
      throw new Error [res.statusCode, body]

    return JSON.parse body

  return loadingOne



starredUrl = (userName, page=1, perPage=100) ->
  url   = "https://api.github.com/users/#{userName}/starred"
  query = "?page=#{page}&per_page=#{perPage}"
  url + query

loadChunks = (userName, pages) ->
  loadingOnes = for page in pages
    loadOne starredUrl userName, page

  return Vow.all(loadingOnes).then (chunks) ->
    [].concat chunks...



loadLoop = (userName, {startPage, receivedEvents, loadingAll}) ->
  loadingChunks = loadChunks userName, [startPage..(startPage + 9)]
  loadingChunks.then (events) ->
    if events.length < 1000
      loadingAll.fulfill receivedEvents.concat events

    else
      loadLoop userName,
        startPage: startPage + 10
        receivedEvents: receivedEvents.concat events
        loadingAll: loadingAll

  loadingChunks.fail (reason) ->
    loadingAll.reject reason

  return loadingAll



loadAll = (userName) ->
  return loadingAll = loadLoop userName,
    startPage: 1
    receivedEvents: []
    loadingAll: Vow.promise()



module.exports = loadAll
if require.main == module
  main = (userName) ->
    loadingAll = loadAll userName
    loadingAll.then((events) ->
      console.log JSON.stringify events, null, '\t'

    ).done()

  userName = process.argv[2] || throw 'no user name'
  main userName
