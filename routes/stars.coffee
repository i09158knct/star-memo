path = require 'path'
mongoose = require 'mongoose'
Repo = mongoose.model 'Repo'
Star = mongoose.model 'Star'

module.exports = (app) ->
  app.get '/', (req, res) ->
    res.render 'index'


  app.put '/stars/:starId.json', (req, res) ->
    _id = req.params.starId
    if _id != req.body.id
      res.statusCode = 400
      res.end 'Invalid id(data and url)'
      return
    newValues =
      tags: req.body.tags
      memo: req.body.memo

    Star
    .findOne({_id})
    .exec (err, star) ->
      throw err if err?
      star.tags = newValues.tags
      star.memo = newValues.memo
      star.save (err) ->
        throw err if err?
        res.statusCode = 200
        res.end 'saved'

  # app.get '/stars.json', (req, res) ->



  app.get '/stars', (req, res) ->
    page  = req.query.page  ||  1
    limit = req.query.limit || 30

    # FIXME:
    count = null
    Star.count({})
    .exec (err, c) ->
      count = c

    Star
    .find({})
    .sort('-created_at')
    .skip((page - 1) * limit)
    .limit(limit)
    .populate('repo')
    .exec (err, stars=[]) ->
      throw err if err?

      res.render 'stars',
        stars: stars
        page : page
        limit: limit
        count: count


  app.get '/stars/search/:scope/:words', (req, res) ->
    page  = req.query.page  ||  1
    limit = req.query.limit || 30

    scope = req.params.scope
    words = parseSearchWords req.params.words
    if scope == 'tags'
      target = $and: (tags: {$in: [word]} for word in words)

      # FIXME:
      count = null
      Star.count({})
      .exec (err, c) ->
        count = c


      Star
      .find(target)
      .sort('-created_at')
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('repo')
      .exec (err, stars=[]) ->
        throw err if err?

        res.render 'stars',
          stars       : stars
          page        : page
          limit       : limit
          count       : count
          scope       : scope
          search_words: req.params.words

    else
      pattern = new RegExp(words.join('|'), 'i')

      Repo
      .find($or: [
        {repo: pattern}
        {description: pattern}
        {'owner.login': pattern}
      ], 'id')
      .exec (err, ids) ->
        # FIXME:
        count = null
        Star.count({})
        .exec (err, c) ->
          count = c

        Star
        .find($or:[
          {repo: {$in: ids}}
          {tags: {$in: [pattern]}}
        ])
        .populate('repo')
        .sort('-created_at')
        .skip((page - 1) * limit)
        .limit(limit)
        .exec (err, stars) ->
          throw err if err?

          res.render 'stars',
            stars       : stars
            page        : page
            limit       : limit
            count       : count
            scope       : scope
            search_words: req.params.words


parseSearchWords = (wordsData) -> wordsData.trim().split(/\s+/)
