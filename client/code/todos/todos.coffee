#
# main client app code
#

# global data store
window.errors = []      # all errors from server stored here

#
# first, render handlerbar template
#
window.Todos = Todos = Ember.Application.create
    LOG_TRANSITIONS: true
    ready: ->
        console.log 'App created and ready...'


# now add route in order to show each template controller.
# Router is only support in Ember-1.0.0-master.
# Todos.Router.map -> 
#     this.resource "index"
#     this.route "check", {path: "/check"}
#     this
# Todos.PrescriptionRoute = Ember.Route.extend 
#   setupController: (controller) ->
#     controller.set('title', "My App");
  
# item object, view can refer here thru view.content.title
Todos.Todo = Em.Object.extend(
    title: null,
    isDone: false
)

# controller ArrayAdapter get items of content [] model
# {{#each Todos.todosController}} or {{#collection contentBinding='Todos.todosController' }}
todosCtrlImpl = 
    content : []

    createTodo: (title) ->
        todo = Todos.Todo.create {title: title}
        this.pushObject todo
        console.log "todoCtrlImpl : createTodo", todo
        console.log 'insert prescription line: ' + title + ' size: ' + this.content.length

    clearCompletedTodos: ->
        this.filterProperty('isDone', true).forEach(this.removeObject, this)

    # http://stackoverflow.com/questions/12777782/ember-computed-properties-in-coffeescript
    remaining: ( ->
        # console.log 'remaining: ', this.filterProperty('isDone', false)
        this.filterProperty('isDone', false).get('length')
    ).property('@each.isDone')

    allAreDone: ( (key, value) ->
        if value isnt undefined
            this.setEach('isDone', value)
            return value
        else
            return !!this.get('length') and this.everyProperty('isDone', true)
    ).property('@each.isDone')

    # awesome coffescript list comprehension
    getObjects : ->
        p.title for p in this.content when p.isDone isnt true

# compatible with ember-1.0.0
#Todos.todosController = Em.ArrayController.create todoCtrlImpl
Todos.TodosController = Ember.ArrayController.extend todosCtrlImpl
Todos.todosController = Todos.TodosController.create()

#  error model, encapsulate error text and other properties.
Todos.Error = Em.Object.extend(
    errtype: null,
    errlist: []
)

# repr error model with object controller, so router can set up MVC for the route
# to display model from this object controller to template. Only available since 1.0.0
# Todos.errorController = Ember.ObjectController.extend
#     getCat: ->
#         return this.errtype

# for error list returned from web service, bind to error controller.
errorsCtrlImpl = 
    content : []
    itemController: 'error'

    createError: (errtype, errlist) ->
        error = Todos.Error.create {errtype: errtype, errlist: errlist}
        this.pushObject error


# compatible with ember-1.0.0
#Todos.errorController = Em.ArrayController.create errorCtrlImpl  
Todos.ErrorsController = Ember.ArrayController.extend errorsCtrlImpl
Todos.errorsController = Todos.ErrorsController.create()


#view created by extend View object. Template refer to the view. 
# {{ #view Todos.StatsView id='stats'}}
statsViewImpl = 
    remainingBinding: 'Todos.todosController.remaining',

    remainingString: ( -> 
        remaining = this.get('remaining');  # <-- refer to remainingBinding -> controller attribute
        console.log 'remainingString :', remaining
        # return remaining + (remaining is 1 ? " item" : " items")
        return if remaining <= 1 then remaining + " prescription" else remaining + " prescriptions"
    ).property('remaining')

Todos.StatsView = Em.View.extend statsViewImpl
    
createTodoViewImpl =
    insertNewline: ->
        value = this.get('value');
        console.log 'CreateTodoView: ', value
        if value
            Todos.todosController.createTodo value
            this.set 'value', ''

Todos.CreateTodoView = Em.TextField.extend createTodoViewImpl


####################################################################################
# Client DOM handler binding 
####################################################################################
# top level bind event to set up all View event callbacks
bindDOMViewEvent = ->
    console.log 'bindDOMViewEvent..'
    
    $('#searchbox').submit (e) ->
        console.log 'searchbox submit...'
        e.preventDefault()
        handleSearchSubmit()
        false

    $('#check').submit (e) ->
        e.preventDefault()
        handleSearchSubmit()
        false

    console.log 'done bindDOMViewEvent..'

# bind server push/bcast event thru socketstream session/channel
ss.event.on 'locpoint', (data) ->
    loc = JSON.parse(data)
    console.log 'locpoint :', loc

dumpPrescription = (item, idx, enums) ->
    console.log item.title, idx

handleSearchSubmit = ->
    # check submit btn handler, ss.rpc call to server
    Todos.todosController.forEach dumpPrescription, this
    args = Todos.todosController.getObjects()
    console.log 'handling submit check :', args
    ss.rpc 'prescription.check.checkError', args, (result) ->
       console.log 'check prescription result: ', result
       setCheckResult result

# errjson in the following format:
# {err-type-1: [note1, err1, note2, err2, ...], err-type-2: [note1, err1, note2, err2]}
setCheckResult = (errjson) ->
    # get check error result back, display it on the screen
    itemcontainer = document.createElement("div")
    itemcontainer.id = "error"
    
    console.log 'setCheckResult :', errjson
    listitems = []
    
    for e of errjson
        console.log e, errjson[e]
        listitems = listitems.concat(appendItems(e, errjson[e]))
        # populate error array controller
        Todos.errorsController.createError e, errjson[e]
    
    styleErrorText listitems
    # Todos.errorController.set 'content', errs  # set ctrller's content property

# pass in 
appendItems = (category, items) ->
    #$("#notes").hide()
    listitems = []
    listitems.push '<li class=rederror>' + category
    listitems.push '<ul>'
    for item, idx in items
        if not (idx % 2)
            listitems.push '<li>' + item + '</li>'
        else
            listitems.push '<li class=rederror>' + item + '</li>'
    listitems.push '</ul></li>'
    console.log 'appendItem : ', listitems
    return listitems

    #listitems.push '<li>' + ' Please be careful ! ' + '</li>'

styleErrorText = (listitems) ->
    $("#errortext").css({display: "inline-block"})
    $("#errorlist").empty()
    $("#errorlist").append(listitems.join(''))
    # error ctrl display set to none at first, enable to show it.
    $("#errorctrl").css({display: "inline-block"})
    #$("#errorlist").css({color: "red"})
    

##--------------------------------
#  put the init function at the bottom
##--------------------------------
init = ->
    console.log 'init ember template and bind event handler'
    bindDOMViewEvent()

window.onloadx = ->
    console.log 'window onload done..., create gmap'
    init()

## init client
console.log 'inside todos.coffee'
init()
