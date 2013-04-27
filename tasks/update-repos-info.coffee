request = require 'request'
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

getUrl = (star) ->
  base = 'https://api.github.com/repos'
  "#{base}/#{star.repo.owner.login}/#{star.repo.name}" + '?client_id=1d7b414dfb52fac9a5b6&client_secret=763ef47953564a5a9638eeec89d86794cc5deb41'

updateStar = (star) ->
  loading = Vow.promise()
  request (getUrl star), (err, res, body) -> loading.sync Vow.invoke ->
    if err?
      throw err
    if res.statusCode != 200
      throw new Error [res.statusCode, body]

    return JSON.parse body

  updating = Vow.promise()
  loading.then((repoInfo) ->
    star.repo.id = repoInfo.id
    star.repo.updated_at = repoInfo.updated_at
    star.repo.description = repoInfo.description
    star.repo.homepage = repoInfo.homepage
    star.repo.forks_count = repoInfo.forks_count
    star.repo.watchers = repoInfo.watchers

    star.repo.save (err) -> updating.sync Vow.invoke ->
      throw err if err?
      return
  )

  return updating

if require.main == module
  mongoose.connect 'localhost', 'tmp'
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'
  db.once 'open', ->
    fetchAllStars().then((stars) ->
      Vow.all (updateStar star for star in stars)
    ).then(->
      console.log 'success'
      db.close()
    , (reason) ->
      db.close()
      throw reason
    ).done()
