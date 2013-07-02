#
# main client app code
#

# global data store
window.errors = []      # all errors from server stored here

#
# first, render handlerbar template
#
window.Todos = Todos = Ember.Application.create
    ready: ->
        console.log 'App created and ready...'


# item object, view can refer here thru view.content.title
Todos.Todo = Em.Object.extend(
    title: null,
    isDone: false
)

# controller ArrayAdapter get items of content [] model
# {{#each Todos.todosController}} or {{#collection contentBinding='Todos.todosController' }}
todoCtrlImpl = 
    content : []

    createTodo: (title) ->
        todo = Todos.Todo.create {title: title}
        this.pushObject todo
        console.log 'insert prescription line: ' + title + ' size: ' + this.content.length

    clearCompletedTodos: ->
        this.filterProperty('isDone', true).forEach(this.removeObject, this)

    # http://stackoverflow.com/questions/12777782/ember-computed-properties-in-coffeescript
    remaining: ( ->
        console.log 'remaining: ', this.filterProperty('isDone', false)
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

Todos.todosController = Em.ArrayController.create todoCtrlImpl
    

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

# {{ view Todos.CreateTodoView id='new-todo' placeholder='what to do'}}
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

setCheckResult = (err) ->
    # get check error result back, display it on the screen
    itemcontainer = document.createElement("div")
    itemcontainer.id = "error"
    
    errors = err.slice()        # make a copy
    if errors.length > 10
        errors.pop()

    console.log 'setCheckResult :', errors
    appendItems('errortext', errors)

appendItems = (id, items) ->
    #$("#notes").hide()
    listitems = []
    for item in items
        listitems.push '<li>' + item + '</li>'

    listitems.push '<li>' + ' Please be careful ! ' + '</li>'

    $("#errortext").css({display: "inline-block"})
    $("#errorlist").empty()
    $("#errorlist").append(listitems.join(''))
    $("#errorlist").css({color: "red"})
    

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
