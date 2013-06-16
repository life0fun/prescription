// My SocketStream 0.3 app

var http = require('http'),
    ss = require('socketstream');

// Define a single-page client, routing endpoint, called 'main'
ss.client.define('main', {
  view: 'app.html',
  css:  ['libs', 'app.styl'],
  code: ['libs/1.jquery.min.js', 'app'],
  tmpl: ['chat']  // load templates/chat/*, refer by ss.tmpl['chat-message'].render({})
});

// ss-jade does not know how to handle SocketStream tag in jade file.
// as a result, has to jade prescription.jade to prescription.html and use html here
ss.client.define('prescription', {
  view:   'prescription.html',
  css:    ['libs', 'prescription.styl'],
  code:   ['libs', 'prescription'],
  tmpl:   []
});

ss.client.define('todos', {
  view:   'todos.html',
  css:    ['libs', 'prescription.styl', 'todos.css'],
  code:   ['libs', 'todos'],
  tmpl:   []
});


// Code Formatters
ss.client.formatters.add(require('ss-stylus'));
ss.client.formatters.add(require('ss-coffee'));
ss.client.formatters.add(require('ss-jade'));


// Use server-side compiled Hogan (Mustache) templates. Others engines available
ss.client.templateEngine.use(require('ss-hogan'));
// use the default template engine, ember, for files under templates/
//ss.client.templateEngine.use('ember');	  // use ember for all templates
ss.client.templateEngine.use('ember', '/todos');
ss.client.templateEngine.use('ember', '/drug');

// Minimize and pack assets if you type: SS_ENV=production node app.js
if (ss.env === 'production') ss.client.packAssets();

// config/set-up/initialize route event handler.
// just pass in ss, router is property of ss.http.router
router = require('./route').init(ss);

// Start web server
var server = http.Server(ss.http.middleware);
server.listen(3000);

// Start SocketStream
ss.start(server);
