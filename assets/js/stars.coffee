#= require backbone/models/star
#= require backbone/views/star
#= require backbone/views/search-star
#= require backbone/views/stars

$ ->
  GHViewer.main = new GHViewer.StarsView()

  do ->
    current = -1

    getStarViews = ->
      GHViewer.main.stars

    getStarView = (index) ->
      GHViewer.main.stars[index]

    scrollToStarOf = (index) ->
      document.body.scrollTop =
        GHViewer.main.stars[index].$el.position().top


    Mousetrap.bind 'ctrl+n', ->
      if current < getStarViews().length - 1
        current++

      scrollToStarOf current


    Mousetrap.bind 'ctrl+p', ->
      if current > 0
        current--

      scrollToStarOf current


    Mousetrap.bind 'ctrl+enter', ->
      scrollToStarOf current

      starView = getStarView current
      starView.editMemo()

      # to don't conflict with starView's 'finish editing' keybinding
      return false
