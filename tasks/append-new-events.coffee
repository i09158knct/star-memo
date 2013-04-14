request = require 'request'
Vow = require 'vow'
mongoose = require 'mongoose'
Event = require '../models/event'


loadAllEvents = require '../lib/load-all-received-events'


fetchLastUpdatedTime = () ->
  fetching = Vow.promise()

  Event
  .findOne({})
  .sort('-created_at')
  .exec (err, event={}) -> fetching.sync Vow.invoke ->
    throw err if err?
    return event.created_at || new Date(0)

  return fetching


extractNewEvents = (baseTime, events) ->
  isNewer = (event) -> (new Date(event.created_at) > baseTime)
  events.filter (event) -> (isNewer event)


saveEvent = (eventInfo) ->
  saving = Vow.promise()

  event = new Event(eventInfo)
  event.save (err) -> saving.sync Vow.invoke ->
    throw err if err?
    return event

  return saving


saveEvents = (eventInfos) ->
  Vow.all (saveEvent eventInfo for eventInfo in eventInfos)



appendNewEvents = (userName) ->
  fetchingLastUpdatedTime = fetchLastUpdatedTime()
  loadingAllEvents = loadAllEvents userName

  extractingNewEvents = Vow.all([
    fetchingLastUpdatedTime
    loadingAllEvents
  ]).spread extractNewEvents

  return extractingNewEvents.then saveEvents



module.exports = appendNewEvents
if require.main == module
  main = (userName) ->
    mongoose.connect 'localhost', 'tmp'
    db = mongoose.connection
    db.on 'error', console.error.bind console, 'connection error:'
    db.once 'open', ->
      appending = appendNewEvents userName
      appending.then((savedEvents)->
        console.log savedEvents.length
        console.log 'success!'

      ).done()

      appending.always(-> db.close()).done()

  userName = process.argv[2] || throw 'no user name'
  main userName
