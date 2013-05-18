Q    = require 'q'
Repo = require '../models/repo'
Star = require '../models/star'


fetchAllStars = ->
  query = Star
  .find({})
  .populate('repo')

  return Q.ninvoke(query, 'exec')


if require.main == module
  settings = require '../settings'
  mongoose = require 'mongoose'

  mongoose.connect settings.dbhost, settings.dbname
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'

  db.once 'open', ->
    fetchAllStars().done(
      (stars) ->
        db.close()
        console.log JSON.stringify stars, null, '\t'
    ,
      (reason) ->
        db.close()
        throw reason
    )
