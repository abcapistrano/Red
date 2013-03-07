$(document).bind('contextmenu', function(event) {

  var url = jQuery.prop(event.target,'href');
var title = event.target.text;
  
  if (url == undefined) {
                 url = window.location.href;
                 title = $(this).attr('title');
}
              
  var info = {
    "command": "addReadingListItem",
    "payload": {
      "url": url,
      "referrer": window.location.href,
      "title": title
    }
  };
  safari.self.tab.setContextMenuEventUserInfo(event, JSON.stringify(info));
});

$('a').click(function(e){
  
  if (e.which == 2) {
    e.preventDefault();
    e.stopPropagation();
    
    var info = {
      "command": "addReadingListItem",
      "payload": {
        "url": $(this).prop('href'),
        "referrer": window.location.href,
        "title": $(this).text()
      }
    };
    var msg = JSON.stringify(info);
             console.log('middleclick');
    safari.self.tab.dispatchMessage('addReadingListItem', msg);    
  
  }
  
           
});

/*
$(window).unload(function() {
                 alert('Handler for .unload() called.');
});*/