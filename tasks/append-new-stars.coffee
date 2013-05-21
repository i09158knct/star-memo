Q      = require 'q'
Repo   = require '../models/repo'
Star   = require '../models/star'
loader = require '../lib/loader'



extractNewWatchEvents = (baseTime, events) ->
  isWatchEvent = (event) ->
    (event.type == 'WatchEvent')
  isNewer = (event) ->
    (new Date(event.created_at) > baseTime)

  events.filter (event) ->
    (isWatchEvent(event) && isNewer(event))



loadRepoInfo = (event) ->
  Q.ninvoke(loader, 'loadRepo', event.repo.name)

loadRepoInfos = (events) ->
  Q.all events.map (event, i) ->
    deferred = Q.defer()
    setTimeout ->
      deferred.resolve loadRepoInfo event
    , (i * 1000)
    return deferred.promise



saveStar = (event, repoInfo) ->
  Q.ninvoke(Star, 'saveRepoAndStar',
    repoInfo,
    {created_at : event.created_at}
  )


saveStars = (events, repoInfos) ->
  if events.length == 0
    Q([])
  else
    Q.all [0..(events.length - 1)].map (i) ->
      saveStar events[i], repoInfos[i]



appendNewStars = ->
  fetchingLastUpdatedTime = Q.ninvoke Star, 'fetchLastUpdatedTime'
  loadingAllEvents = Q.ninvoke(loader, 'loadAllPublicEvents')

  extractingNewWatchEvents = Q.all([
    fetchingLastUpdatedTime
    loadingAllEvents
  ]).spread(extractNewWatchEvents)

  loadingNewRepoInfos = extractingNewWatchEvents.then(loadRepoInfos)

  return Q.all([
    extractingNewWatchEvents
    loadingNewRepoInfos
  ]).spread(saveStars)



module.exports = appendNewStars
if require.main == module
  settings = require '../settings'
  mongoose = require 'mongoose'

  mongoose.connect settings.dbhost, settings.dbname
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'

  db.once 'open', ->
    appendNewStars().done(
      (results) ->
        db.close()
        console.log results.length
        console.log 'success!'
    ,
      (reason) ->
        db.close()
        throw reason
    )
