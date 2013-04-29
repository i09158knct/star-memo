request       = require 'request'
Q             = require 'q'
Event         = require '../models/event'
loader        = require '../lib/loader'


fetchLastUpdatedTime = () ->
  query = Event
    .findOne({})
    .sort('-created_at')

  return Q.ninvoke(query, 'exec').then(
    (event={}) -> event.created_at || new Date(0)
  )


extractNewEvents = (baseTime, events) ->
  isNewer = (event) -> (new Date(event.created_at) > baseTime)
  events.filter (event) -> (isNewer event)


saveEvent = (eventInfo) ->
  event = new Event(eventInfo)
  return Q.ninvoke(event, 'save').then(-> event)


saveEvents = (eventInfos) ->
  return Q([]) if eventInfos.length == 0
  return Q.all eventInfos.map (eventInfo) -> saveEvent eventInfo



appendNewEvents = ->
  fetchingLastUpdatedTime = fetchLastUpdatedTime()
  loadingAllEvents = Q.ninvoke(loader, 'loadAllReceivedEvents')

  extractingNewEvents = Q.all([
    fetchingLastUpdatedTime
    loadingAllEvents
  ]).spread(extractNewEvents)

  return extractingNewEvents.then(saveEvents)



module.exports = appendNewEvents
if require.main == module
  settings = require '../settings'
  mongoose = require 'mongoose'

  mongoose.connect settings.dbhost, settings.dbname
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'

  db.once 'open', ->
    appendNewEvents().done(
      (results) ->
        db.close()
        console.log results.length
        console.log 'success!'
    ,
      (reason) ->
        db.close()
        throw reason
    )
