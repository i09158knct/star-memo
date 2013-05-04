Q      = require 'q'
Repo   = require '../models/repo'
Star   = require '../models/star'
loader = require '../lib/loader'


fetchAllStars = ->
  query = Star
    .find({})
    .populate('repo')

  return Q.ninvoke(query, 'exec')


updateStar = (star) ->
  fullname = "#{star.repo.owner.login}/#{star.repo.name}"
  loading = Q.ninvoke(loader, 'loadRepo', fullname)
  loading.then(
    (repoInfo) ->
      repo = star.repo

      repo.previous.forks_count = repo.forks_count
      repo.previous.watchers = repo.watchers

      repo.id = repoInfo.id
      repo.updated_at = repoInfo.updated_at
      repo.description = repoInfo.description
      repo.homepage = repoInfo.homepage
      repo.html_url = repoInfo.html_url
      repo.language = repoInfo.language
      repo.forks_count = repoInfo.forks_count
      repo.watchers = repoInfo.watchers
      return Q.ninvoke(repo, 'save')
  )


# Deferred loading
updateAllStars = (stars) ->
  Q.all stars.map (star, i) ->
    onFailed = (star) -> (reason) ->
      console.error "- #{star.repo.name}: Communication error!"
      console.error "  ", reason

    deferred = Q.defer()
    setTimeout ->
      deferred.resolve(updateStar(star).fail(onFailed))
    , (i / 10)
    return deferred.promise


if require.main == module
  settings = require '../settings'
  mongoose = require 'mongoose'

  mongoose.connect settings.dbhost, settings.dbname
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'

  db.once 'open', ->
    fetchAllStars().then(updateAllStars).then(
      (result) ->
        db.close()
        console.log 'success!'
    ,
      (reason) ->
        db.close()
        throw reason
    )
