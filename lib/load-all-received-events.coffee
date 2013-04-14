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



publicEventsUrl = (userName, page=1) ->
  url   = "https://api.github.com/users/#{userName}/received_events"
  query = "?page=#{page}" + '&client_id=1d7b414dfb52fac9a5b6&client_secret=763ef47953564a5a9638eeec89d86794cc5deb41'
  url + query

loadAll = (userName) ->
  loadingOnes = for page in [1..10]
    loadOne publicEventsUrl userName, page

  return Vow.all(loadingOnes).then (chunks) ->
    [].concat chunks...



module.exports = loadAll
if require.main == module
  main = (userName) ->
    loadingAll = loadAll userName
    loadingAll.then((events) ->
      console.log JSON.stringify events, null, '\t'

    ).done()

  userName = process.argv[2] || throw new Error 'no user name'
  main userName
