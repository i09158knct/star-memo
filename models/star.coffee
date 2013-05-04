mongoose = require 'mongoose'

Repo = require './repo'

{ObjectId} = mongoose.Schema.Types

starSchema = new mongoose.Schema
  repo:
    type: ObjectId
    ref: 'Repo'
  tags: [String]
  memo: String
  created_at:
    type: Date

starSchema.statics.fetchLastUpdatedTime = (cb) ->
  @
  .findOne({})
  .sort('-created_at')
  .exec (err, star) ->
    cb? err, star?.created_at || new Date(0)


# starSchema.index

# starSchema.set 'autoIndex', false

###
starSchema.statics.saveRepoAndStar = (repoInfo, starInfo={}) ->
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
###


module.exports = mongoose.model 'Star', starSchema

