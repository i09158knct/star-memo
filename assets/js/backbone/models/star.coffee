GHViewer.Star = class Star extends Backbone.Model
  constructor: () ->
    super

  defaults:
    repo: 'repo-object-id'
    tags: []
    memo: ''

  sync: (method, cb) ->
    switch method
      when 'update'
        json = @toJSON()
        $.ajax "/stars/#{json.id}.json",
          type: 'PUT'
          contentType: 'application/json'
          data: JSON.stringify json
          success: cb
