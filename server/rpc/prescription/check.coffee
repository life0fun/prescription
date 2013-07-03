# Server-side Code
spawn = require('child_process').spawn

ErrorDB = require('./errordb').ErrorDB

#streamer = SS.require('streamer').create()

# global list of all ws clients
# global.M = undefined  // please no global(module global) object.
_clientWS = {}
errorDB = undefined

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
  errorDB ?= ErrorDB.create(ss.db)  # ref to ss.api.add('db', db) by ss.db

  console.log 'ws rpc req :', req   # log all the requests

  # load middlewares to process this WS req.
  req.use('session')
  #req.use('debug', 'cyan')
  #req.use('posthandle.handlePost')  # 

  # searched out data will be publish.socket to client
  checkError: (args) ->
    console.log 'prescription check:', args
    sock = req.socketId
    errorDB.getError (err) =>
      #res ["error", "warning", "efefe", "eiofe ", "ce fefe"]
      res err
  
