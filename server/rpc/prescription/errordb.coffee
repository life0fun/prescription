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
    errFileDir = __dirname + '/../../../data/'
    drugfiles = []
    # drugfiles = [ __dirname + '/../../../data/DrugIsTakenWithContraindication.csv', 
    #             __dirname + '/../../../data/PatientHasDiseaselimitation.csv',
    #             __dirname + '/../../../data/PatientHasContraindication.csv' ]
    errData = {}

    # init, dep inject openned mongo db
    constructor: (m) ->
        M = m
        drugfiles = fs.readdirSync errFileDir
        console.log 'constructor with m', M?

    # factory pattern, hide new. dep inject all collaborators.
    @create: (m) ->
        return new ErrorDB(m)

    getError: (onData) ->
        # callback carry the file idx, instead of store index global var.
        onReadFile = (idx, resultjson) ->
            # copy primiate result 
            console.log 'one read file: ', resultjson
            for e of resultjson
                errData[e] = resultjson[e]

            # if still more files under data folder to be read
            if idx < drugfiles.length - 1
                readCSV drugfiles[idx+1], idx+1, onReadFile
            else
                onData?(errData)

        readCSV drugfiles[0], 0, onReadFile

    readCSV = (filename, idx, onReadDone) ->
        regexp = /[A-Z][a-z]+/g
        errors = []
        errfilename = filename.match(regexp).join(' ')
        console.log 'readCsv ', filename

        onRecord = (row, index) ->
            if index > 0
                console.log 'csv row :', row[1]
                errtxt = row[1].substring(0, row[1].indexOf('['))
                errors.push errtxt
                # errData.push errtxt

        onEnd = (lines) ->
            csvresult = {}
            csvresult[errfilename] = errors
            console.log 'err :', errfilename, errors, csvresult
            onReadDone?(idx, csvresult)

        csv().from.stream(fs.createReadStream(errFileDir + filename))
             .on('record', onRecord)
             .on('end', onEnd)

exports.ErrorDB = ErrorDB

# uncomment out for unit test
#m = 'm'
#loc = ErrorDB.create(m)
