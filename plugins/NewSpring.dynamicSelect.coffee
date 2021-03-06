###
@class DynamicSelect

@author
  Edolyne Long
  NewSpring Church

@version 1.0

@note

###

class DynamicSelect

  constructor: (@data, attr, toggle) ->

    if @data instanceof jQuery then @data = @data.get(0)

    if typeof @data isnt 'string'
      # Get data from attribute
      params = @data.attributes[attr].value.split(',')

      params = params.map (param) -> param.trim()

      id = params[0]
    else
      id = @data


    @_properties =
      _id : id
      triggers: document.querySelectorAll( '[' + attr + '*="' + id + '"]' )
    
    if EventEmitter? then @.events = new EventEmitter()

    if typeof @data isnt 'string'
      @.bindChange()
    
    
  updateDynamicLink: () ->
    # get the select that triggered the event
    dynamicSelect = 
      document.querySelectorAll('[data-dynamic-select="' + @_properties._id + '"]')[0]
  
    # get the matching button that needs to be updated
    dynamicLinkCTA = 
      document.querySelectorAll('[data-dynamic-link-cta="' + @_properties._id + '"]')[0]

    # get the link from the select
    dynamicSelectLink = dynamicSelect.value

    # set the dynamicLinkCTA to the dynamicSelectLink
    dynamicLinkCTA.href = dynamicSelectLink

    # update the classes on the button
    @.toggleClasses(dynamicSelect, dynamicLinkCTA)


  toggleClasses: (dynamicSelect, dynamicLinkCTA) ->
    
    # Toggle the active / disabled link classes
    if dynamicSelect.value
      core.removeClass dynamicLinkCTA, "disabled"
    else
      core.addClass dynamicLinkCTA, "disabled"
      

  bindChange: =>

    for trigger in @_properties.triggers

      change = (e) =>
        e.preventDefault()
        # unless @_properties.modal?
        #   @.getModal()
        @.updateDynamicLink()

      trigger.addEventListener('change', change, false)

    this

if core?
  core.addPlugin('DynamicSelect', DynamicSelect, '[data-dynamic-select]')