Vow      = require 'vow'
mongoose = require 'mongoose'

Repo = require '../models/repo'
Star = require '../models/star'

loadAllStars     = require '../lib/load-all-stars'
loadAllDatetimes = require '../lib/load-all-datetimes-starred'



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


saveAll = (repoInfos, datetimeTable) ->

  getDatetimeStarred = (repoInfo) ->
    key = "#{repoInfo.owner.login}/#{repoInfo.name}"
    return datetimeTable[key]

  savingOnes = for repoInfo in repoInfos
    saveRepoAndStar repoInfo,
      time: getDatetimeStarred(repoInfo)

  return Vow.all(savingOnes)


do ->
  username = throw new Error 'change me'
  password = throw new Error 'change me'

  loadingAllStars     = loadAllStars     username
  loadingAllDatetimes = loadAllDatetimes username , password

  mongoose.connect 'localhost', 'tmp'
  db = mongoose.connection
  db.on 'error', console.error.bind console, 'connection error:'
  db.once 'open', ->
    Vow.all([
      loadingAllStars
      loadingAllDatetimes
    ]).spread(saveAll).then((results)->
      console.log 'success!'
      db.close()
    ).done()
