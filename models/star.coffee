Q        = require 'q'
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

starSchema.statics.saveRepoAndStar = (repoInfo, starInfo={}, cb=->) ->
  repo = new Repo(repoInfo)
  star = new @
    repo       : repo
    tags       : starInfo.tags || [repo.language]
    memo       : starInfo.memo || ''
    created_at : starInfo.created_at || new Date

  Q.ninvoke(repo, 'save').then(-> Q.ninvoke(star, 'save'))
  .nodeify(cb)

starSchema.statics.findWithPaginate = (target, page, limit) ->
  @
  .find(target)
  .populate('repo')
  .sort('-created_at')
  .skip((page - 1) * limit)
  .limit(limit)

starSchema.statics.update = (_id, attr, cb=->) ->
  Q.ninvoke(@.findOne({_id}), 'exec').then(
    (star) ->
      star.tags = attr.tags
      star.memo = attr.memo
      Q.ninvoke(star, 'save')

  ).nodeify(cb)



module.exports = mongoose.model 'Star', starSchema

