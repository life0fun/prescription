/*
 * api handle of http post data
 */

var http = require('http')
var qs = require('querystring')

//
// API handle
// django api and its request handler
//
// application = webapp.WSGIApplication([
//     ('/api/site/info.json', SiteInfoHandler),
//     ('/api/nodes/all.json', NodesAllHandler),
//
// class SiteInfoHandler(webapp.RequestHandler)
//	def get(self):
//  def post(self, data):
//

exports.init = function(ss) {

	return {
		processFix: function(fixbody, cb){
            console.log('api-processFix:', fixbody);
            fix = fixbody;
			console.log('api-processFix:', fix.lat, fix.lng);
			cb(fix, null);
		},
		getLocation: function(addr, cb) {
            console.log('api-getLocation:', addr);
		}
	}
};
