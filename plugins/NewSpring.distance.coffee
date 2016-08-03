###
@class Googleapis, Geolocation

@author
  Edolyne Long
  NewSpring Church

@version 0.1

@note
  Googleapis required to initialize Google maps
  Geolocation renders map view of data parameters

###

class Distance

  ###
  Constructor function runs when object gets initialized

  @param {Object} options for setting up the class

  ###
  constructor: (@data, attr) ->

    # Check and see if called by jQuery and convert to node
    if @data instanceof jQuery then @data = @data.get(0)

    # Get data from attribute
    params = @data.attributes[attr].value
      # .split(',')
      .split(/[,](?=[^\]]*?(?:\[))/g)

    if params.length > 2
      meta = params.splice(0, 2)
      json = params.join(',')
      params = meta.concat json

    params = params.map (param) -> param.trim()

    choosenLocations = params[1].replace(/[\[\]']+/g,'').split(',')
    choosenLocations = choosenLocations.map (param) -> param.trim()

    if typeof choosenLocations is 'string'
      choosenLocations = [choosenLocations]

    locations = try JSON.parse(params[2]); catch e

    unless choosenLocations[0] is 'all'
      locations = locations.filter( (location) =>
        for campus in choosenLocations
          if location._id
            .toLowerCase()
            .replace(' ', '')
            .indexOf(
              campus
                .toLowerCase()
                .replace(' ', '')
            ) > -1
            return true
          else false
      )


    # bind element and properties to private @_properties variable
    @_properties = {
      _id : params[0]
      endpoint: "https://maps.googleapis.com/maps/api/distancematrix/json?"
      target: @data
      location: choosenLocations
      locations: locations
      multi: false
      attr: attr
    }


    if @_properties.location[0] is 'all' or @_properties.location.length > 1
      @_properties.multi = true


    if EventEmitter? then @.events = new EventEmitter()

    @.bindEvents()


  bindEvents: () =>

    @.events.on('campus-found', (campus) =>

      for trigger in @_properties.findLocation
        core.removeClass trigger, 'btn--icon btn--filled'
        trigger.innerHTML = trigger.dataset.originalText
    )

    @.events.on('finding-closest', () =>

      for trigger in @_properties.findLocation
        trigger.dataset.originalText = trigger.innerText
        trigger.innerHTML = 'Loading...<span class="icon icon--loading"></span>'
        core.addClass trigger, 'btn--icon btn--filled'
    )

    # Add event listener to find the click.

    @_properties.findLocation = document.querySelectorAll(
      '[' + @_properties.attr + '-trigger="' + @_properties._id + '"]'
    )

    for trigger in @_properties.findLocation

      enter = (e) =>
        if e.keyCode is 13
          click(e)

      click = (e) =>
        e.preventDefault()

        if @_properties.multi
          @.findClosest(trigger.previousElementSibling.value)
          @.scrollToList()

      adjacentInput = trigger.previousElementSibling

      if trigger.tagName is "INPUT"
        trigger.addEventListener('keydown', enter, false)
      else
        trigger.addEventListener('click', click, false)

    this

  scrollToList: () =>

    document.querySelector('[' + @_properties.attr + '-scroll="' + @_properties._id + '"]').scrollIntoView({block: "end", behavior: "smooth"})

  createList: () =>
    compiledTemplate = Handlebars.getTemplate('locations_listitem')

  findClosest: (location) =>
    findClosest = document.querySelectorAll(
      '[' + @_properties.attr + '-trigger="' + @_properties._id + '"]'
    )

    @_properties.findLocation = findClosest

    for trigger in findClosest

      if location
        if document.querySelectorAll('[data-destination-item]')?
          @.calculateDistance(location)
      else
        return false

    this

  buildDestinationString: () =>

    if @_properties?.locations?
      @_properties.locations.map((x) =>
        "#{x.location.street1} #{x.location.city}, #{x.location.state} #{x.location.zip}"
      ).join("|")

  calculateDistance: (location) =>

    variables = { origin: location, destinations: @.buildDestinationString() };

    query = "query GeoLocate($origin:String, $destinations: String) { geolocate(origin: $origin, destinations: $destinations) { destination_addresses, origin_addresses, rows { elements { distance { text, value }, duration { text, value }, status } } } }";

    response = $.ajax({
      url: 'https://alpha-api.newspring.cc/graphql?query=' + encodeURI(query),
      data: {variables:variables},
      dataType: 'json',
      success: @.destinationSort
    });

  destinationSort: (response) =>

    # Check that we have a valid response with rows, and that the origin isn't blank
    if response.data?.geolocate?.rows?[0].elements? and response.data.geolocate.origin_addresses[0] isnt ""

      destinationDistances = response.data.geolocate.rows[0].elements.slice()

      destinationArray = []

      for destination, itemIndex in destinationDistances

        currentDestination = @_properties.locations[itemIndex]

        # Create an item in the campusList array
        destinationItem = {
          _id  : @_properties.locations[itemIndex].count
          distance : "#{destination.distance.value}"
          miles : "#{destination.distance.text.replace(' mi','')}"
        }

        # # Inject that item in the campusList array
        destinationArray.push(destinationItem)

      destinationArray.sort (a, b) ->
        a.distance - b.distance

      @.sortMarkup(destinationArray)

  sortMarkup: (destinations) =>


    # need to find a way to wildcard the latter part of the string
    destinationItems = document.querySelectorAll('[' + @_properties.attr + '-item^="' + @_properties._id + ',"]')

    # document.querySelectorAll('[data-destination-item]')

    sortedDestinationArray = []

    destinations.map((destination) =>
      targetDestination = document.querySelector('[' + @_properties.attr + '-item="' + @_properties._id + ', ' + destination._id + '"]')

      if destination.miles? and destinationItems isnt null

        # Add push-quarter--bottom Class To H3
        targetHeading = targetDestination.getElementsByTagName("H3")[0]

        if targetHeading
          core.addClass targetHeading,'push-quarter--bottom'

        # Create Mileage Information Markup
        milesText = document.createElement 'p'

        # Add a data attribute so we can remove it the next time
        milesText.setAttribute("data-distance-miles", "#{destination._id}")

        milesMarkup = '<small><em>' + destination.miles + ' miles away' + '</em></small>'

        # Find Existing Mileage Information
        existingMiles = targetDestination.querySelector('[data-distance-miles]')

        # Add mileage information beneath heading
        # If there is existing mileage information, replace the innerHTML
        if existingMiles
          existingMiles.innerHTML = milesMarkup
        # Else insert the created node
        else if milesText
          milesText.innerHTML = milesMarkup
          targetHeading.parentNode.insertBefore milesText, targetHeading.nextSibling

      sortedDestinationArray.push targetDestination
    )

    @.rebuildMarkup(sortedDestinationArray)

  rebuildMarkup: (list) =>

    destinationIndex = 0

    list.map((element) =>

      # OuterHTML is broken somewhere in here

      destinationTarget = document.querySelector('[' + @_properties.attr + '-item="' + @_properties._id + ', ' + destinationIndex + '"]')

      if destinationIndex is 0
        core.addClass element, 'card--selected'
      else
        core.removeClass element, 'card--selected'

      destinationTarget.outerHTML = element.outerHTML

      destinationIndex = destinationIndex + 1
    )

if core?
  core.addPlugin('Distance', Distance, '[data-distance]')