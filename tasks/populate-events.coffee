Vow = require 'vow'
mongoose = require 'mongoose'
Event = require '../models/event'


loadAllEvents = require '../lib/load-all-events'

saveEvent = (eventInfo) ->
  saving = Vow.promise()

  event = new Event(eventInfo)
  event.save (err) -> saving.sync Vow.invoke ->
      throw err if err?
      return

  return saving


saveAllEvents = (eventInfos) ->
  Vow.all (saveEvent eventInfo for eventInfo in eventInfos)


do ->
  main = (userName) ->
    mongoose.connect 'localhost', 'tmp'
    db = mongoose.connection
    db.on 'error', console.error.bind console, 'connection error:'
    db.once 'open', ->
      loadingAll = loadAllEvents userName
      savingAll = loadingAll.then saveAllEvents
      savingAll.then(->
        console.log 'succsess!'

      ).done()

      savingAll.always(-> db.close()).done()

  userName = process.argv[2] || throw 'no user name'
  main userName
