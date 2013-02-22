document.addEventListener('contextmenu', function () {
  var link = null;
  var currentElement = window.getSelection().focusNode;
  while (currentElement != null)
  {
      if (currentElement.nodeType == Node.ELEMENT_NODE && currentElement.nodeName.toLowerCase() == 'a')
      {
          link = currentElement;
          break;
      }
      currentElement = currentElement.parentNode;
  }
  
  var info = {
  
    "url": link.href,
    "referrer": window.location.href,
    "title": window.getSelection().toString()
  
  
  
  };
  
  safari.self.tab.setContextMenuEventUserInfo(event, JSON.stringify(info));
}, false);