# Server-side Code
spawn = require('child_process').spawn

LocationDB = require('./locationdb').LocationDB

#streamer = SS.require('streamer').create()

# global list of all ws clients
# global.M = undefined  // please no global(module global) object.
_clientWS = {}
locationdb = undefined

# @deprecated db init. use ss.api.add('db', db)
# AppGlobals = {}
#require('./db')(AppGlobals)

# Define actions which can be called from the client using 
# ss.rpc('module.ACTIONNAME', param1, param2...)
# when famework called this actions function thru 
#   actions = file.actions(req,cb,ss), retured an obj with all actions.
#   route each API to actions[api]
#
exports.actions = (req, res, ss) ->

  console.log 'ss.env : ', ss.env
  #locationdb ?= LocationDB.create(AppGlobals.M)
  locationdb ?= LocationDB.create(ss.db)  # ref to ss.api.add('db', db) by ss.db

  console.log 'ws rpc req :', req   # log all the requests

  # load middlewares to process this WS req.
  req.use('session')
  #req.use('debug', 'cyan')
  #req.use('posthandle.handlePost')  # 

  # searched out data will be publish.socket to client
  checkError: (args) ->
    console.log 'prescription check:', args
    sock = req.socketId
    err = ['not for pregant', 'do not drink with juice']
    res err


################# #################
# private func declared with =, not :
################# #################

# when server started, run db populate routine, in a spawned process ?
startSolana = () ->
    sol = spawn('coffee', ['lib/server/solana.coffee'])
    sol.stdout.on 'data', (data) ->
        console.log data.toString().replace("\n", '')
    sol.stderr.on 'data', (data) ->
        console.log data.toString().replace("\n", '')
    sol.on 'exit', (code, signal) ->
        console.log 'SOLANA EXITING...', code, ':', signal

sendLoc: (ss, socket, loc) ->
    ss.publish.socket socket, 'locpoint', JSON.stringify(loc)

# put is after all declaration and definition to avoid function hoist
#startSolana()
