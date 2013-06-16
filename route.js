/*
 * http route handling module
 */

var http = require('http')
var url = require('url')

// django api and its request handler
// application = webapp.WSGIApplication([
//     ('/api/site/info.json', SiteInfoHandler),
//     ('/api/nodes/all.json', NodesAllHandler),
//
// class SiteInfoHandler(webapp.RequestHandler)
//  def get(self):

// invoking init just set-up event listener, or bind event.
// other type of init returns a closure{}
//
exports.init = function(ss) {
    api = require('api').init(ss);

    // connect app == ss.http.middleware
    ss.http.middleware.prepend(ss.http.connect.bodyParser())

    // if there is no listener, http router will drop post request.
    ss.http.router.on('/', function(req, res) {
        console.log('app-route-/, request on root');
        res.serveClient('todos');  //
    });

    ss.http.router.on('/demo', function(req, res) {
        console.log('app-route-/, request on root');
        res.serveClient('main');  //
    });

    // serve the static http assets first, to show web page, and ws request follows.
    ss.http.router.on('/drug', function(req, res) {
        console.log('app-router-on-/prescription req method:', req.method);
        res.serveClient('prescription');
    });

    // serve the static http assets first, to show web page, and ws request follows.
    ss.http.router.on('/todos', function(req, res) {
        console.log('app-router-on-/todos req method:', req.method);
        res.serveClient('todos');
    });

    // req body is GET request's req body
    // req.body = curl -d lat=37.846 -d lng=-122.276 localhost:3000/solana/post
    // req.parse = req.curl localhost:3000/solana/post?lat=37.8\&lng=-122.72
    ss.http.router.on('/solana/post', function(req, res){
        var reqparse = url.parse(req.url, true);
        data = req.body;
        console.log('req.path:', reqparse);
        console.log('app-router-on-solana/post post data::', data);

        api.processFix(data, function(fixobj, err){
            console.log('lat/lng at:', fixobj.lat, fixobj.lng, ' err : ', err);
            loc = {};
            loc.latlng = [];
            loc.latlng[0] = fixobj.lat;
            loc.latlng[1] = fixobj.lng;
            console.log('ss.publish.all :', loc);
            ss.api.publish.all('locpoint', JSON.stringify(loc));
        });

        res.serveClient('api');
    });

    // serve the static http assets first, to show web page, and ws request follows.
    ss.http.router.on('/todos', function(req, res) {
        console.log('app-router-on-/todos req method:', req.method);
        res.serveClient('todos');
    });

    // serve the static http assets first, to show web page, and ws request follows.
    ss.http.router.on('/contacts', function(req, res) {
        console.log('app-router-on-/contacts req method:', req.method);
        res.serveClient('contacts');
    });

    ss.http.router.on('/bootstrap', function(req, res) {
        console.log('app-router-on-/bootstrap req method:', req.method);
        res.serveClient('bootstrap');
    });
};
