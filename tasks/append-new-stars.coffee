request       = require 'request'
Q             = require 'q'
Repo          = require '../models/repo'
Star          = require '../models/star'
loader        = require '../lib/loader'


fetchLastUpdatedTime = () ->
  query = Star
  .findOne({})
  .sort('-created_at')

  return Q.ninvoke(query, 'exec').then(
    (star) -> star.created_at
  )


extractNewWatchEvents = (baseTime, events) ->
  isWatchEvent = (event) -> (event.type == 'WatchEvent')
  isNewer = (event) -> (new Date(event.created_at) > baseTime)
  events.filter (event) -> (isWatchEvent(event) && isNewer(event))



loadRepoInfo = (event) ->
  Q.ninvoke(loader, 'loadRepo', event.repo.name)

loadRepoInfos = (events) ->
  Q.all events.map (event) ->
    loadRepoInfo event



saveStar = (event, repoInfo) ->
  repo = new Repo(repoInfo)
  star = new Star
    repo       : repo
    tags       : [repo.language]
    memo       : ''
    created_at : event.created_at

  deferredSavingRepo = Q.defer()
  deferredSavingStar = Q.defer()

  do ->
    deferredSavingRepo.resolve Q.ninvoke(repo, 'save').then(-> repo)

  deferredSavingRepo.promise.then ->
    deferredSavingStar.resolve Q.ninvoke(star, 'save').then(-> star)

  return Q.all([
    deferredSavingRepo.promise
    deferredSavingStar.promise
  ])


saveStars = (events, repoInfos) ->
  return Q([]) if events.length == 0
  return Q.all [0..(events.length - 1)].map (i) ->
    saveStar events[i], repoInfos[i]



appendNewStars = ->
  fetchingLastUpdatedTime = fetchLastUpdatedTime()
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
      (result) ->
        db.close()
        console.log result.length
        console.log 'success!'
    ,
      (reason) ->
        db.close()
        throw reason
    )
