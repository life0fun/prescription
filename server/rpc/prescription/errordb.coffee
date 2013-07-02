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
    drugfile = __dirname + '/../../../data/DrugIsTakenWithContraindication.csv'
    errData = []

    # init, dep inject openned mongo db
    constructor: (m) ->
        M = m
        console.log 'constructor with m', M?

    # factory pattern, hide new. dep inject all collaborators.
    @create: (m) ->
        return new ErrorDB(m)

    getError: (onData) ->
        readCSV drugfile, onData

    readCSV = (filename, onData) ->
        onRow = (row, index) ->
            errData.push row
            console.log 'csv row: ', index, row

        onEnd = (lines) ->
            console.log 'total lines: ', lines
            onData?(errData)

        console.log 'readCsv ', filename
        csv().from.stream(fs.createReadStream(filename))
             .on('record', onRow)
             .on('end', onEnd)

exports.ErrorDB = ErrorDB

# uncomment out for unit test
#m = 'm'
#loc = ErrorDB.create(m)
