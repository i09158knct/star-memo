Vow              = require 'vow'
Repo             = require '../models/repo'
Star             = require '../models/star'
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
      throw err if err?
      return repo

  savingRepo.then ->
    star.save (err) -> savingStar.sync Vow.invoke ->
      throw err if err?
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
  mongoose = require 'mongoose'
  readline = require 'readline'

  rl = readline.createInterface
    input: process.stdin
    output: process.stderr

  asking1 = Vow.promise()
  asking2 = Vow.promise()

  do           -> rl.question 'username: ', asking1.fulfill.bind asking1
  asking1.then -> rl.question 'password: ', asking2.fulfill.bind asking2
  asking2.then -> rl.close()

  Vow.all([asking1, asking2]).spread((username, password) ->
    loadingAllStars     = loadAllStars     username
    loadingAllDatetimes = loadAllDatetimes username, password

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
  ).done()
