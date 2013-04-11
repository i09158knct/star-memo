GHViewer.SearchStarView = class SearchStarView extends Backbone.View
  constructor: () ->
    super


  events:
    'submit': 'onsubmit'


  onsubmit: (event) ->
    event? && event.preventDefault()

    scope = @getScope()
    words = @getWords()

    if words != ''
      document.location = "/stars/search/#{scope}/#{words}"


  getScope: () -> @$('[name=scope]:checked').val()
  getWords: () -> @$('[name=words]').val().trim()


