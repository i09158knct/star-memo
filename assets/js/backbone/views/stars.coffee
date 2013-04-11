GHViewer.StarsView = class StarsView extends Backbone.View
  constructor: () ->
    super
    targets = @$('.star')
    @stars = for el in targets
      new GHViewer.StarView(el: el)
    @search = new GHViewer.SearchStarView
      el: @$('#search-star')


  el: 'body'



