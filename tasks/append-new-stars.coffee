request       = require 'request'
Vow           = require 'vow'
Repo          = require '../models/repo'
Star          = require '../models/star'
loadAllEvents = require '../lib/load-all-events'


fetchLastUpdatedTime = () ->
  fetching = Vow.promise()

  Star
  .findOne({})
  .sort('-created_at')
  .exec (err, star) -> fetching.sync Vow.invoke ->
    throw err if err?
    return star.created_at

  return fetching


extractNewWatchEvents = (baseTime, events) ->
  isWatchEvent = (event) -> (event.type == 'WatchEvent')
  isNewer = (event) -> (new Date(event.created_at) > baseTime)
  events.filter (event) -> (isWatchEvent(event) && isNewer(event))



loadRepoInfo = (event) ->
  loading = Vow.promise()

  url = event.repo.url
  request url, (err, res, body) -> loading.sync Vow.invoke ->
    throw err if err?
    return JSON.parse body

  return loading


loadRepoInfos = (events) -> Vow.all (loadRepoInfo event for event in events)



saveStar = (event, repoInfo) ->
  savingRepo = Vow.promise()
  savingStar = Vow.promise()

  repo = new Repo(repoInfo)
  star = new Star
    repo       : repo
    tags       : [repo.language]
    memo       : ''
    created_at : event.created_at

  do ->
    repo.save (err) -> savingRepo.sync Vow.invoke ->
      throw err if err?
      return repo

  savingRepo.then ->
    star.save (err) -> savingStar.sync Vow.invoke ->
      throw err if err?
      return star

  return Vow.all([savingRepo, savingStar])


saveStars = (events, repoInfos) ->
  console.log events,repoInfos
  return Vow.promise([]) if events.length == 0
  len = events.length
  Vow.all (saveStar events[i], repoInfos[i] for i in [0..(len - 1)])



appendNewStars = (username) ->
  fetchingLastUpdatedTime = fetchLastUpdatedTime()
  loadingAllEvents = loadAllEvents username

  extractingNewWatchEvents = Vow.all([
    fetchingLastUpdatedTime
    loadingAllEvents
  ]).spread extractNewWatchEvents

  loadingNewRepoInfos = extractingNewWatchEvents.then loadRepoInfos

  return Vow.all([
    extractingNewWatchEvents
    loadingNewRepoInfos
  ]).spread saveStars



module.exports = appendNewStars
if require.main == module
  username = process.argv[2] || throw 'no user name'
  do (username) ->
    mongoose = require 'mongoose'
    mongoose.connect 'localhost', 'tmp'
    db = mongoose.connection
    db.on 'error', console.error.bind console, 'connection error:'
    db.once 'open', ->
      appending = appendNewStars username
      appending.then((result)->
        console.log result.length
        console.log 'success!'

      ).done()

      appending.always(-> db.close()).done()
