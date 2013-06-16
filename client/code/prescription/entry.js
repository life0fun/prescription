// This file automatically gets called first by SocketStream and must always exist

// Make 'ss' available to all modules and the browser console
window.ss = require('socketstream');

ss.server.on('disconnect', function(){
  console.log('Connection down :-(');
});

ss.server.on('reconnect', function(){
  console.log('Connection back up :-)');
});

// change back to onload to test google.map.Map()
window.onloadx = function() {
    console.log('window onload event callback');
    mylat = new google.maps.LatLng(42.288,-87.995984);
    myOptions = {
        zoom: 10,
        center: mylat,
        mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    gmap = new google.maps.Map(document.getElementById("map_canvas"), myOptions)
    width = window.innerWidth;
    height = window.innerHeight;
    console.log('heatmap overlay created...', width, height, mylat);
}

// jquery ready happens first, when we have template, need to render as early as possible.
$(document).ready(function(){
    console.log('jQuery document ready:');
    require('/app');
});

// this happened later than jquery ready...
ss.server.on('ready', function(){
  // Wait for the DOM to finish loading
  jQuery(function(){
    // Load app
    console.log('ss.server.ready, hello');
    //require('/app');
  });
