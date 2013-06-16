//
// create client model, view,and controller using ember js lib
//

window.Todos = Todos = Ember.Application.create({
    ready: function() {
        console.log('App created and ready...'); 
    }
});

// item object, view can refer here thru view.content.title
Todos.Todo = Em.Object.extend({
    title: null,
    isDone: false
});

// controller ArrayAdapter, model in an array
// {{#collection contentBinding='Todos.todosController' }}
Todos.todosController = Em.ArrayController.create({
    content: [],

    // no init: funciton() {}, 
    
    createTodo: function(title) {
        var todo = Todos.Todo.create({ title: title });
        this.pushObject(todo);
        console.log('createTodo: ' + title + ' size: ' + this.content.length);
    },

    clearCompletedTodos: function() {
        this.filterProperty('isDone', true).forEach(this.removeObject, this);
    },

    remaining: function() {
        return this.filterProperty('isDone', false).get('length');
    }.property('@each.isDone'),

    allAreDone: function(key, value) {
        if (value !== undefined) {
            this.setEach('isDone', value);  
            return value;
        } else {
            return !!this.get('length') && this.everyProperty('isDone', true);
        }
    }.property('@each.isDone')
});


// view created by extend View object. Template refer to the view. 
// {{ #view Todos.StatsView id='stats'}}
Todos.StatsView = Em.View.extend({
    // view property bind to controller's attribute for auto update
    remainingBinding: 'Todos.todosController.remaining',

    remainingString: function() {   // function as temp view's computed property.
        var remaining = this.get('remaining');  // <-- refer to remainingBinding -> controller attribute
        return remaining + (remaining === 1 ? " item" : " items");
    }.property('remaining')  // <-- as property so tempview {{named_var}} can ref to it.
});

// {{ view Todos.CreateTodoView id='new-todo' placeholder='what to do'}}
Todos.CreateTodoView = Em.TextField.extend({
    // text field, insert new line
    insertNewline: function() {
        var value = this.get('value');
        console.log('CreateTodoView: ', value);
        if (value) {
            Todos.todosController.createTodo(value);
            this.set('value', '');
        }
    }
});
