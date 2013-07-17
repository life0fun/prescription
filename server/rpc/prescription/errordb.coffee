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

class ErrorDB
    # class private static variable sits at top level in scope chain.
    M = undefined
    errFileDir = __dirname + '/../../../data/'
    drugfiles = []
    errData = {}

    # init, dep inject openned mongo db
    constructor: (m) ->
        M = m
        drugfiles = fs.readdirSync errFileDir
        console.log 'constructor with m', M?

    # factory pattern, hide new. dep inject all collaborators.
    @create: (m) ->
        return new ErrorDB(m)

    # main entrance called from check module.
    getError: (onData) ->
        # callback carry the file idx, instead of store index global var.
        onReadFile = (idx, resultjson) ->
            # copy primiate result 
            console.log 'one read file: ', resultjson
            for e of resultjson
                errData[e] = resultjson[e]

            # if still more files under data folder to be read, 
            if idx < drugfiles.length - 1
                # static scoped and resolve to the highest scope chain
                readCSV drugfiles[idx+1], idx+1, onReadFile
            else
                onData?(errData)

        readCSV drugfiles[0], 0, onReadFile

    readCSV = (filename, idx, onReadDone) ->
        regexp = /[A-Z][a-z]+/g
        csvresult = {}
        errors = []
        errfilename = filename.match(regexp).join(' ')
        console.log 'readCsv ', filename

        # callback for each row
        onRecord = (row, index) ->
            if index is 0   # do not read col header
                return
            
            errtxt = row[1].substring(0, row[1].indexOf('['))
            errsub = row[2].substring(0, row[2].indexOf('['))
            errobj = row[3].substring(0, row[3].indexOf('['))
            errors.push errtxt + ' ==> ' + errsub + ' conflict with ' + errobj

        onEnd = (lines) ->
            csvresult[errfilename] = errors
            onReadDone?(idx, csvresult)

        csv().from.stream(fs.createReadStream(errFileDir + filename))
             .on('record', onRecord)
             .on('end', onEnd)

exports.ErrorDB = ErrorDB

# uncomment out for unit test
#m = 'm'
#loc = ErrorDB.create(m)
