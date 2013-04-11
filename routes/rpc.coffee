path = require 'path'
request = require 'request'
Vow = require 'vow'
mongoose = require 'mongoose'
Repo = require '../models/repo'
Star = require '../models/star'

module.exports = (app) ->
  app.get '/rpc/get-recent-stars', (req, res) ->
    loadAllEvents = require '../lib/load-all-events'
    loadingAll = loadAllEvents 'i09158knct'
    gettingLastTime = getLastUpdatedTime()
    Vow.all([loadingAll, gettingLastTime]).spread((events, lastUpdatedTime) ->
      recents = events.filter (event) ->
        event.created_at > lastUpdatedTime && event.type == 'WatchEvent'

      loadingList = recents.map (recent) ->
        loadingRepoInfo = Vow.promise()
        repoUrl = recent.repo.url
        request repoUrl, (err, res, body) -> loadingRepoInfo.sync Vow.invoke ->
          throw err if err?
          return JSON.parse body

        return loadingRepoInfo

      savingRecents = Vow.promise()
      Vow.all(loadingList).then (repoInfos) ->
        savingList = repoInfos.map (repoInfo, i) ->
          saveRepoAndStar repoInfo,
            created_at: recents[i].created_at
        savingRecents.sync Vow.all(savingList)

      savingRecents.then ->
        res.statusCode = 200
        res.end 'success.'

    , (reason) ->
      res.statusCode = 500
      res.end 'failed. ' + reason

    ).done()


getLastUpdatedTime = () ->
  gettingStar = Vow.promise()

  Star
  .findOne({})
  .sort('-created_at')
  .exec (err, star) -> gettingStar.sync Vow.invoke ->
    throw err if err?
    return star

  return gettingStar


saveRepoAndStar = (repoInfo, starInfo={}) ->
  savingRepo = Vow.promise()
  savingStar = Vow.promise()
  repo = new Repo(repoInfo)
  star = new Star
    repo       : repo
    tags       : starInfo.tags || [repo.language]
    memo       : starInfo.memo || ''
    created_at : starInfo.time || new Date

  do ->
    repo.save (err) -> savingRepo.sync Vow.invoke ->
      err && throw err
      return repo

  savingRepo.then ->
    star.save (err) -> savingStar.sync Vow.invoke ->
      err && throw err
      return star

  return Vow.all([savingRepo, savingStar])



###
  {
    "id": "1709039108",
    "type": "WatchEvent",
    "actor": {
      "id": 1635689,
      "login": "i09158knct",
      "gravatar_id": "4894d9823bd6dff26d7f33bb23b3a92f",
      "url": "https://api.github.com/users/i09158knct",
      "avatar_url": "https://secure.gravatar.com/avatar/4894d9823bd6dff26d7f33bb23b3a92f?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png"
    },
    "repo": {
      "id": 9116407,
      "name": "boyers/raytracer",
      "url": "https://api.github.com/repos/boyers/raytracer"
    },
    "payload": {
      "action": "started"
    },
    "public": true,
    "created_at": "2013-04-08T09:25:25Z"
  },
###