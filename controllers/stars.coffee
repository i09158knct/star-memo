Q        = require 'q'
path     = require 'path'
mongoose = require 'mongoose'
Repo     = mongoose.model 'Repo'
Star     = mongoose.model 'Star'

parseSearchWords = (wordsData) ->
  wordsData.trim().split(/\s+/)

fetchTargetAndCount = (target, page, limit) ->
  finding = Q.ninvoke Star.findWithPaginate(target, page, limit), 'exec'
  counting = Q.ninvoke Star.count(target), 'exec'
  Q.all([finding, counting])

makeOnFailHandler = (res) ->
  (reason) ->
    res.statusCode = 500
    res.end 'error'
    throw reason


module.exports = (app) ->
  app.put '/stars/:starId.json', (req, res) ->
    _id = req.params.starId

    if _id != req.body.id
      res.statusCode = 400
      res.end 'Invalid ID(data and url)'
      return

    Star.update _id, req.body, (err) ->
      if err?
        res.statusCode = 500
        res.end 'error'
        throw reason
      else
        res.statusCode = 200
        res.end 'saved'


  # app.get '/stars.json', (req, res) ->


  app.get '/stars', (req, res) ->
    page  = req.query.page  ||  1
    limit = req.query.limit || 30
    target = {}

    fetchTargetAndCount(target, page, limit).spread(
      (stars=[], count) ->
        res.render 'stars',
          stars: stars
          page : page
          limit: limit
          count: count

    , makeOnFailHandler(res)).done()


  app.get '/stars/search/:scope/:words', (req, res) ->
    page  = req.query.page  ||  1
    limit = req.query.limit || 30

    scope = req.params.scope
    words = parseSearchWords req.params.words

    deferredResolving = Q.defer()

    if scope == 'tags'
      deferredResolving.resolve $and: (tags: {$in: [word]} for word in words)
    else
      pattern = new RegExp(words.join('|'), 'i')

      Repo
      .find($or: [
        {repo: pattern}
        {description: pattern}
        {'owner.login': pattern}
      ], 'id')
      .exec (err, ids) ->
        deferredResolving.resolve $or: [
          {repo: {$in: ids}}
          {tags: {$in: [pattern]}}
        ]

    deferredResolving.promise.then(
      (target) -> fetchTargetAndCount(target, page, limit)
    ).spread(
      (stars=[], count) -> res.render 'stars',
        stars       : stars
        page        : page
        limit       : limit
        count       : count
        scope       : scope
        search_words: req.params.words

    ).fail(makeOnFailHandler(res)).done()

