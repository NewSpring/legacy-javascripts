###
@class FullScreen

@author
  James E Baxley III
  NewSpring Church

@version 0.1

@note
  used to turn an element into a full screen element
  Resize is bound

###

class FullScreen

  constructor: (@data, attr) ->


    # Check and see if called by jQuery and convert to node
    if @data instanceof jQuery then @data = @data.get(0)

    # Get data from attribute
    params = @data.attributes[attr].value.split(',')

    params = params.map (param) -> param.trim()


    @_properties = {
      target : @data
      # height : params[1]
      # width : params[2]
      id: params[0]
      mobile : params[1]
    }

    if @_properties.mobile and window.matchMedia("(max-width: 480px)").matches
      @.bindResize @_properties.target
    else if @_properties.mobile is "undefined" or @_properties.mobile is false
      @.bindResize @_properties.target

  expandElement: =>

    windowHeight = window.innerHeight
    windowWidth = window.innerWidth

    acutalHeight = windowHeight

    images = @_properties.target.getElementsByTagName 'img'
    if images.length isnt 0
      for image in images
        expandedSize = image.width * (windowHeight / image.height)
        offsetLeft = (expandedSize - windowWidth) / 2

        if offsetLeft > 0
          image.style.left = "-" + offsetLeft + "px"

    # if @_properties.height isnt `undefined`
    #   acutalHeight = windowHeight - @_properties.height

    unless @_properties.width is 'false'
      @_properties.target.style.width = windowWidth + "px"

    unless @_properties.height is 'false'
      @_properties.target.style.height = acutalHeight + "px"

      if @_properties.target.tagName is 'IFRAME'
        @_properties.target.height = acutalHeight

    this

  bindResize: (element) =>

    debounce = null

    debounce ?= new Debouncer @.expandElement

    window.addEventListener "resize", debounce, false

    @.expandElement()

if core?
  core.addPlugin('FullScreen', FullScreen, '[data-fullscreen]')
