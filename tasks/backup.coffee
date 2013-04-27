Vow = require 'vow'
mongoose = require 'mongoose'
Repo = require '../models/repo'
Star = require '../models/star'


fetchAllStars = ->
  fetching = Vow.promise()

  Star
  .find({})
  .populate('repo')
  .exec (err, stars) -> fetching.sync Vow.invoke ->
    throw err if err?
    return stars

  return fetching


if require.main == module
  mongoose.connect 'localhost', 'tmp'
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'
  db.once 'open', ->
    fetching = fetchAllStars()

    fetching.then((stars) ->
      console.log JSON.stringify stars, null, '\t'
    ).done()

    fetching.always(-> db.close())
