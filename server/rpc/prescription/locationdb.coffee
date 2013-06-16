#
# this file contains location related methods. The methods interact with Mongodb
# locs collection that is GeoIndexed.
#

sys = require 'sys'
EventEmitter = require('events').EventEmitter
fs = require 'fs'
path = require 'path'
#_ = require 'underscore'

# if js, no coffee class, obj = require('./file.js').init(m). <-- init factory return closure obj
# exports.init = function(M) { sect = 0; return {foo: function(){}, bar: function(){} } }

class LocationDB
    # class private static variable refed by name directly
    M = undefined
    LOCS = 'locs'  # location collection name
    LOCFILE = path.join(__dirname, '../../public/data/loc.data')
    LocData = []
    LOCDATAKEY = 'locdatakey'  # redis list of loc 
    LiveTimer = null

    DBPARAM = do ->
        colname = 'locs'
        setColName: (name)->
            colname = name

    # init, dep inject openned mongo db
    constructor: (m) ->
        M = m
        console.log 'constructor with m', M?

    # factory pattern, hide new. dep inject all collaborators. Only knows what needs to known.
    @create: (m) ->
        return new LocationDB(m)

    sendLoc: (ss, socket, loc) ->
        #console.log 'sendLoc sock:', socket, ' data:', loc
        #ss.publish.socketId socket, 'locpoint', JSON.stringify(loc)
        ss.publish.all 'locpoint', JSON.stringify(loc)

    readLocData : (col, file) ->
        fs.readFile file, (err, data) =>
            throw err if err
            content = data.toString()
            lines = content.split '\n'
            for l in lines
                if l.length == 0
                    continue
                @storeData col, l   # called from cb, so cb needs to use fat arrow.
            @setLiveTimer -> # start location stream timer

    storeData : (col, l) ->
        col.insert JSON.parse(l), (err, docs) -> console.log 'added location:'+docs
        latlng = JSON.parse(l).loc
        console.log 'storeData ->' + latlng + ' lat:'+latlng[0] + ':'+latlng[1]
        R.lpush LOCDATAKEY, JSON.stringify(latlng), (err, status) ->   # 8) "42.289383,-88.001001"
        LocData.push latlng
        console.log 'LocData:' + LocData[LocData.length-1][0] + LocData[LocData.length-1][1]

    ''' just read data from log and pump into R'''
    readLocDataPopRedis : (cb) ->
        fs.readFile LOCFILE, (err, data) =>   # need closure so to ref set live timer
            throw err if err
            content = data.toString()
            lines = content.split '\n'
            for l in lines
                if l.length == 0
                    continue
                latlng = JSON.parse(l).loc
                R.lpush LOCDATAKEY, JSON.stringify(latlng), (err, status) ->
                LocData.push latlng
                console.log 'LocData:' + LocData[LocData.length-1][0] + LocData[LocData.length-1][1]

            R.lindex LOCDATAKEY, 2, (err, data) ->
                console.log 'R lindex:' + JSON.parse(data)
            @setLiveTimer -> # start stream timer
            stream.emit('locdataready', {data:'ready'})

    ''' when doc read out from db, already json'''
    readCollection : (err, col) =>
        col.find().each (err, doc) ->
            return if not doc?
            latlng = doc.loc
            console.log 'readCollection ->' + latlng + ' lat:'+latlng[0] + ':'+latlng[1]
            R.lpush LOCDATAKEY, JSON.stringify(latlng), (err,status) ->
                console.log 'inserted to Redis:' + latlng # 8) "42.289383,-88.001001"
            LocData.push latlng

    ''' redis is in-memory, volatile after restart '''
    fetchData : ->
        R.lrange LOCDATAKEY, 0, -1, (err, docs) ->
            for loc in docs
                LocData.push loc.split(',')
                console.log 'LocData:' + LocData[LocData.length-1][0] + ':' + LocData[LocData.length-1][1]
        if not LocData.length
            M.collection LOCS, @readCollection

    ''' populate location collection if does not exist '''
    populateLocation : (colname, cb) ->
        console.log 'populateLocations : ' + colname
        LOCS = colname
        M.collectionNames colname, (err, l) =>  #list of collection names as db.col
            console.log 'colletion exists:' + col.name for col in l #[{ name: 'location.locs' }]
            if not l.length
                M.collection colname, @addLocation  # now context is down to when cb invoked.
            else if not LocData.length
                @fetchData()
                console.log 'collection exist start timer'
            @setLiveTimer -> # start stream timer
            stream.emit('locdataready', {data:'ready'})

    # add location data into collection, col obj returned from colname map.
    addLocation : (err, col) =>
        #col.insert {loc:[42.005753, -88.102734]},(err,docs) -> console.log 'added:'+docs
        #col.insert {loc:[42.296108, -88.003106]},(err,docs) -> console.log 'added:'+docs
        #col.insert {loc:[42.300405, -87.999999]},(err,docs) -> console.log 'added:'+docs
        @readLocData col, LOCFILE
        @indexLocation col, 'loc'

    # index the col, col is the result of M.collection colname
    indexLocation : (col, field) ->
        console.log 'indexLocation...'
        locd = {}
        locd[field] = '2d'  # need 2d indexing
        col.ensureIndex locd, (err, result) -> console.log 'ensureIndex:' + result

    # format mongo query object
    formatQueryObject : (args) ->
        #The distance unit is the same as in your coordinate system
        #{latlng:{$near:[42.3,-88.0], $maxDistance: 0.10}}
        #{stm:new Date("2011-11-14 21:43:35.370Z")}
        #{stm:{$gte:new Date(2011, 10, 14, 15, 43, 35, 370)}}
        #{latlng:{$near: [1,5], $maxDistance:5}, $where:'this.stm.getHours() >= 15 && this.stm.getHours() <= 21'}
        console.log 'format args:', args
        queryobj = {}
        if args.latlng
            queryobj.latlng = {}
            queryobj.latlng.$near = args.latlng
            queryobj.latlng.$maxDistance = args.dist
        if args.where.sdate and args.where.sdate isnt '0'
            ymd = args.where.sdate.split('-')
            console.log ymd
            queryobj.stm = {}
            queryobj.stm.$gt = new Date(ymd[0], ymd[1]-1, ymd[2])  # month starts from 0
        if args.where.edate and args.where.edate isnt '0'
            ymd = args.where.edate.split('-')
            queryobj.etm = {}
            queryobj.etm.$lt = new Date(ymd[0], ymd[1]-1, ymd[2])  # month starts from 0

        hourgap = ''  # check against the end time
        if args.where.shour and args.where.shour isnt '0'
            hourgap = ' this.etm.getHours() >= ' + args.where.shour
        if args.where.ehour and args.where.ehour isnt '0'
            if hourgap isnt ''
                hourgap += ' && '
            hourgap += 'this.etm.getHours() <= ' + args.where.ehour

        if hourgap isnt ''
            queryobj.$where = hourgap

        queryobj.dur = {}
        queryobj.dur.$lt = 1200
        if args.where.duration
            queryobj.dur.$gt = parseInt(args.where.duration)

        console.log 'formatQueryObj:', queryobj
        return queryobj

    # find locations nearby, the unit of maxdistance, the same unit as your data unit.(lat/lng deg)
    # http://stackoverflow.com/questions/5319988/how-is-maxdistance-measured-in-mongodb
    findLocation : (lat, lng, radius) ->  # all func should take arguments obj and a callback!!!
        console.log 'findLocation: ' + lat + ',' + lng
        # fetch the collection by name, new collection returned in callback
        M.collection LOCS, (err, collection) ->  # new collection returned
            #collection.find {loc:{$near:[42.3,-88.0], $maxDistance: 10}}, (err, cursor) ->
            collection.find {loc:{$near:[lat,lng], $maxDistance: radius}}, (err, cursor) =>
                cursor.each (err, doc) =>
                    console.log 'findLocation Nearby:' + doc if doc?
                    if doc?
                        SS.server.app.publishLocation doc.loc[0], doc.loc[1]

    nearbyLoc : (args, cb) ->
        console.log 'nearbyLoc:', args
        queryobj = @formatQueryObject(args)
        M.collection LOCS, (err, collection) ->
            collection.ensureIndex {latlng:'2d'}, {background:true}, (err, result) -> console.log err if err
            collection.find queryobj, {limit:100, sort:'dur'}, (err, cursor) =>
                console.log 'db find err:' + err if err
                cursor.toArray (err, docs) ->
                    cb docs

    findApi : (whereobj, cb) ->
        console.log 'findApi : ', whereobj
        M.collection LOCS, (err, collection) ->
            collection.find whereobj, {limit:100}, (err, cursor) =>
                console.log 'findApi err: ' + err if err
                cursor.toArray (err, docs) ->
                cb docs

    clearLiveTimer : ->
        if LiveTimer?
            clearInterval LiveTimer
            LiveTimer = null

    setLiveTimer : ->
        if not LiveTimer?
            offset = 0
            streamLoc = do (offset) ->
                ''' need to return a callback which close the passed in loop index '''
                ->
                    start = offset
                    end = if offset+20 >= LocData.length then LocData.length-1 else offset+20
                    SS.server.app.publishLocation LocData[idx][0], LocData[idx][1] for idx in [start..end]  # inclusive of both ends
                    console.log 'streamLoc: offset='+offset + ' :' + LocData[offset][0]
                    offset = (end + 1) % LocData.length

            LiveTimer = setInterval streamLoc, 1000
            console.log 'setLiveTimer for every 1000...'

exports.LocationDB = LocationDB

# uncomment out for unit test
#m = 'm'
#loc = LocationDB.create(m)
