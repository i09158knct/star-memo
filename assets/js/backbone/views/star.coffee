GHViewer.StarView = class StarView extends Backbone.View
  constructor: (options) ->
    super
    @model = parseModelFromDOM(@el) unless @model?
    @listenTo @model, 'change', @render



  templateTag: (obj) ->
    _.template($('#template-tag').html())(obj)
  templateTagEditing: (obj) ->
    _.template($('#template-tag-editing').html())(obj)
  templateMemoEditing: (obj) ->
    _.template($('#template-memo-editing').html())(obj)



  events:
    'click .memo-edit': 'editMemo'
    'click .memo-editing-tag-remove': 'removeTag'
    'click .memo-editing-tag-add': 'addTag'
    'keypress .memo-editing-new-tag input': 'pressEnter'
    'keypress .memo-editing': 'editingShortcuts'
    'click .memo-editing-cancel': 'cancelEditing'
    'click .memo-editing-ok': 'finishEditing'



  render: () ->
    json = @model.toJSON()
    @$('.memo-body').text json.memo
    $tags = @$('.memo-tags')
    $tags.empty()
    for tagName in json.tags
      $tags.append @templateTag({tagName})
    @


  renderEditForm: () ->
    json = @model.toJSON()
    $el = $ $.parseHTML @templateMemoEditing(json)
    $newTagForm = $el.find('.memo-editing-new-tag')
    for tagName in json.tags
      $(@templateTagEditing({tagName})).insertBefore $newTagForm
    @$('.memo-editing').html $el



  editingShortcuts: (event) ->
    if event.keyCode == 13 && event.ctrlKey
      @finishEditing()


  editMemo: (event) ->
    event.preventDefault() if event?
    @$('.memo').addClass('hide')
    @$('.memo-editing').removeClass('hide')

    @renderEditForm()
    @$('.memo-editing-new-tag input').focus()


  removeTag: (event) ->
    event.preventDefault()
    $(event.target).parent().remove()

  pressEnter: (event) ->
    if event.keyCode == 13
      @addTag(event)
  addTag: (event) ->
    event.preventDefault()

    $newTagForm = @$('.memo-editing-new-tag')
    $nameHolder = $newTagForm.find('input')
    tagName = $nameHolder.val()
    return if tagName == ''
    $nameHolder.val('')

    $tag = $ $.parseHTML @templateTagEditing({tagName})
    $tag.insertBefore $newTagForm



  beforeEndEditing: ->
    @$('.memo').removeClass('hide')
    @$('.memo-editing').addClass('hide')
    @$(':focus').blur()


  cancelEditing: (event) ->
    event?.preventDefault()
    @beforeEndEditing()

  finishEditing: (event) ->
    event?.preventDefault()
    @beforeEndEditing()


    $wrapper = @$('.memo-editing')
    memo = $wrapper.find('.memo-editing-body').val()
    tags = for tag in @$('.memo-editing-tag')
      $(tag).find('input').val()

    @model.set({memo, tags})
    @model.sync 'update', () ->
      console.log arguments...


parseModelFromDOM = (el) ->
  tags = $(el).find('.memo-tag').toArray().map (tag) ->
    $(tag).text()
  memo = $(el).find('.memo-body').text()
  id = $(el).data('memo-id')

  new GHViewer.Star({tags, memo, id})
