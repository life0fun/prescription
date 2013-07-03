#
# this module responsible for reading cvs file under /data folder and
# persist data either in memory or in db
#

sys = require 'sys'
csv = require 'csv'
EventEmitter = require('events').EventEmitter
fs = require 'fs'
path = require 'path'
#_ = require 'underscore'

# if js, no coffee class, obj = require('./file.js').init(m). <-- init factory return closure obj
# exports.init = function(M) { sect = 0; return {foo: function(){}, bar: function(){} } }

class ErrorDB
    # class private static variable refed by name directly
    M = undefined
    drugfiles = [ __dirname + '/../../../data/DrugIsTakenWithContraindication.csv', 
                __dirname + '/../../../data/PatientHasDiseaselimitation.csv',
                __dirname + '/../../../data/PatientHasContraindication.csv' ]
    errData = []

    # init, dep inject openned mongo db
    constructor: (m) ->
        M = m
        console.log 'constructor with m', M?

    # factory pattern, hide new. dep inject all collaborators.
    @create: (m) ->
        return new ErrorDB(m)

    getError: (onData) ->
        i = 0
        onReadFile =  ->
            if i < drugfiles.length - 1
                i += 1
                readCSV drugfiles[i], onReadFile
            else
                onData?(errData)

        readCSV drugfiles[i], onReadFile

    readCSV = (filename, onReadDone) ->
        onRecord = (row, index) ->
            if index > 0
                console.log 'csv row :', row[1]
                errtxt = row[1].substring(0, row[1].indexOf('['))
                errData.push errtxt

        onEnd = (lines) ->
            console.log 'total lines: ', lines
            onReadDone?()

        console.log 'readCsv ', filename
        csv().from.stream(fs.createReadStream(filename))
             .on('record', onRecord)
             .on('end', onEnd)

exports.ErrorDB = ErrorDB

# uncomment out for unit test
#m = 'm'
#loc = ErrorDB.create(m)
