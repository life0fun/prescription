#
# Single page app Client-side Code, each page is an Ember.Application.create()
# all fns and constants are attached as props of global window object.
#
#   ss.rpc 'module.api', args, cb
#
# should use MVC js lib(Ember, backbone, etc) to create views and models.
# then use client routing js lib(finch, crossroads, pathjs) to formalize requests into routes.
#

window.Drugs = Drugs = Ember.Application.create({
  ready: ->
    console.log("Ember App Drugs created, init")
    #init()
})

# {{ view Todos.CreateTodoView id='new-todo' placeholder='what to do'}}
Drugs.CreateDrugsView = Em.TextField.extend({
  insertNewline: ->
    value = this.get('value')
    console.log('CreateDrugView: ', value)
    if (value)
      #Drugs.drugsController.createDrug(value)
      this.set('value', '');
})

# 
# top level bind event to set up all View event callbacks
bindDOMViewEvent = () ->
    console.log 'bindDOMViewEvent'
    google.maps.event.addListener heatmap.gmap, 'click', (event) ->
        console.log 'map clicked geo : ' + event.latLng
        geoCodeLatLng(event.latLng)
        cb = (result) -> console.log 'map clicked result:', result
        searchNearby event.latLng.lat(), event.latLng.lng()

    $('#searchbox').submit (e) ->
        console.log 'searchbox submit...'
        e.preventDefault()
        handleSearchSubmit()
        false

    $('#timerange').submit (e) ->
        e.preventDefault()
        heatmap.where.sdate = $('#timerange [name=sdate]').val()
        heatmap.where.edate = $('#timerange [name=edate]').val()
        heatmap.where.shour = $('#timerange [name=shour]').val()
        heatmap.where.ehour = $('#timerange [name=ehour]').val()
        heatmap.where.duration = $('#timerange [name=duration]').val()
        sd = new Date(heatmap.where.sdate)
        ed = new Date(heatmap.where.edate)
        if sd.toString() is 'Invalid Date'
            alert('wrong start date : ' + heatmap.where.sdate)
        if ed.toString() is 'Invalid Date'
            alert('wrong end date : ' + heatmap.where.edate)
        console.log 'timerange submit:', heatmap.where
        handleSearchSubmit()
        false

    console.log 'done bindDOMViewEvent for gmaps...'


########################################
# server socket event handler.
########
# handle server broadcast datapoint msg, args contains only lat/lng
ss.event.on 'datapoint', (data) ->
    if not heatmap.lastlat?
        mapPanTo data.lat, data.lng

    heatmap.lastlat = data.lat
    heatmap.lastlng = data.lng
    heatmap.repeatcnt = 0
    #addDataPoint data.lat, data.lng, Math.floor(Math.random()*100) # count is random in 100
    addDataPoint data.lat, data.lng, 1
    
# handle msg from web socket
ss.event.on 'startstream', (obj) ->
    for k, v of obj
        console.log k, v

ss.event.on 'locpoint', (data) ->
    loc = JSON.parse(data)
    console.log 'locpoint :', loc
    latlng = new google.maps.LatLng(loc.latlng[0], loc.latlng[1])
    venue = locInfo(loc)
    drawMarker(latlng, venue)
    #if loc.name? or loc.addr?
    #   drawMarker(latlng, loc.name + " " + loc.addr)

########################################
# client DOM handler and server api binder
######

test = ->
    console.log 'testing...'

clearOverlay = () ->
    console.log 'clear overlay...', heatmap.alllocs
    while heatmap.alllocs.length
        m = heatmap.alllocs.pop()
        console.log 'clearing marker:', m
        m.setMap(null)

# the searched out locpoint is handled by event.
searchNearby = (lat, lng) ->
    args = {}
    args.latlng = [lat, lng]
    args.dist = 1
    args.where = heatmap.where   # ref assign. not obj clone
    console.log 'searchNearby:', args
    ss.rpc 'solana.query', args, (result)->
        console.log 'nearby search of clicked loc results:', result

handleSearchSubmit = () ->
    addr = $('#searchbox input:text').val()
    heatmap.where.addr = addr
    console.log 'searching: ', heatmap.where
    #eval('var obj='+venue)
    clearOverlay()
    geoCodeAddr heatmap.where.addr, (latlng) ->
        heatmap.where.latlng = latlng
        console.log 'searching: ', heatmap.where.addr, latlng.lat(), latlng.lng()
        searchNearby latlng.lat(), latlng.lng()

geoCodeAddr = (addr, cb) ->
    console.log 'geoCodeAddr:', addr
    heatmap.geocoder.geocode {address:addr}, (result, status) ->
        console.log 'geoCodeAddr status:', status, result
        if status is google.maps.GeocoderStatus.OK
            console.log 'geoCodeAddr:', result[0].geometry.location, result[0].formatted_address
            cb result[0].geometry.location
        else
            searchNearby 12.28, 33.56

geoCodeLatLng = (latlng) ->
    console.log 'geoCodeLatLng: '
    #req = new google.maps.GeocoderRequest({location:latlng})
    #heatmap.geocoder.geocode {location:latlng}, (result, status) ->
    #    console.log 'geocode status:', status
    #    if status is google.maps.GeocoderStatus.OK
    #        console.log 'geoCodeLatLng:', result[0].formatted_address
    #        drawMarker latlng, result[0].formatted_address

drawMarker = (latlng, title) ->
    console.log 'drawMarker :', latlng.lat(), latlng.lng(), title
    marker = new google.maps.Marker({
        position: latlng,
        map: heatmap.gmap,
        animation: google.maps.Animation.DROP,
        title: title
    })

    marker.setDraggable(true)
    heatmap.alllocs.push(marker)

    setInfoWindow = do (marker) ->
        () =>
            infowindow.close() if infowindow
            infowindow = new google.maps.InfoWindow({
                content:'<div id="content"><p>'+title+'<br/></p></div>'
            })
            infowindow.open(heatmap.gmap, marker)

    google.maps.event.addListener(marker, 'click', setInfoWindow)

    heatmap.gmap.setCenter(latlng)
    heatmap.gmap.setZoom(11)

mapPanTo = (lat, lng) ->
    latlng = new google.maps.LatLng lat, lng
    #heatmap.gmap.panTo latlng
    heatmap.gmap.setCenter latlng

addDataPoint = (lat, lng, cnt) ->
    console.log 'heatmap addDataPoint:' + lat + ':' + lng + ':' + cnt
    heatmap.heatmap.addDataPoint lat, lng, cnt
    #mapPanTo lat, lng
    setRepeatTimer()

locInfo = (loc) ->
    title = ''
    if loc.venue?
      for v in loc.venue
        title += v.name + ' - ' + v.addr + ' - ' + v.cat
        title += '<br>'
    title += (new Date(loc.stm)).toString().substr(0,21) + ' - ' + (new Date(loc.etm)).toString().substr(0,21) + ' stay ' + loc.dur
    return title

fakeDataPoint = ->
    if heatmap.repeatcnt > Number.MAX_VALUE
        clearRepeatTimer()
    else
        heatmap.repeatcnt += 1
        console.log 'periodic fake data point...:' + heatmap.repeatcnt
        addDataPoint heatmap.lastlat, heatmap.lastlng, heatmap.repeatcnt

fadeOut = ->
    console.log 'fading out....'
    heatmap.heatmap.fadeOut()

clearRepeatTimer = ->
    if heatmap.timer?
        clearInterval heatmap.timer
        heatmap.timer = null
        heatmap.repeatcnt = 0

setRepeatTimer = ->
    if not heatmap.timer?
        clearRepeatTimer()
        heatmap.timer = setInterval fadeOut, 2000
        console.log 'setInterval for fadeOut every...5000'

##--------------------------------
#  put the init function at the bottom
##--------------------------------
init = ->
    console.log 'init client map and bind event handler'
    createHeatmap()
    bindDOMViewEvent()

# window is global singleton object. add fn prop to it.
window.onloadx = ->
    console.log 'window onload done..., create gmap'
    init()

## init client
#console.log 'inside prescription.coffe'
#init()
