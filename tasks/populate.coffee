Q                = require 'q'
Repo             = require '../models/repo'
Star             = require '../models/star'
loader           = require '../lib/loader'
loadAllDatetimes = require '../lib/load-all-datetimes-starred'

saveAll = (repoInfos, datetimeTable) ->
  getDatetimeStarred = (repoInfo) ->
    datetimeTable["#{repoInfo.owner.login}/#{repoInfo.name}"]

  Q.all repoInfos.map (repoInfo) ->
    Q.ninvoke(Star, 'saveRepoAndStar',
      repoInfo,
      {created_at: getDatetimeStarred(repoInfo)}
    )

populate = (username, password) ->
  loadingAllStars = Q.ninvoke loader, 'loadAllStars'
  loadingAllDatetimes = loadAllDatetimes username, password
  Q.all([loadingAllStars, loadingAllDatetimes]).spread(saveAll)


module.exports = populate
if require.main == module
  settings = require '../settings'
  mongoose = require 'mongoose'
  readline = require 'readline'

  rl = readline.createInterface
    input: process.stdin
    output: process.stderr

  deferredAsking = Q.defer()
  rl.question 'username:', (username) ->
    rl.question 'password: ', (password) ->
      rl.close()
      deferredAsking.resolve [username, password]

  deferredAsking.promise.done ([username, password]) ->
    # mongoose.connect settings.dbhost, settings.dbname
    mongoose.connect settings.dbhost, 'poplatetest'
    db = mongoose.connection
    db.on 'error', console.error.bind console, 'connection error:'

    db.once 'open', ->
      populate(username, password).done(
        (results) ->
          db.close()
          console.log results.length
          console.log 'success!'
      ,
        (reason) ->
          db.close()
          throw reason
      )
