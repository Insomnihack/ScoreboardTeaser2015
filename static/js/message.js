function getMessages(callback, execNewEvent, neverDrawn){
  requestMessage = new XMLHttpRequest();
  requestMessage.open('GET', CacheRoot+GetMessagesR, true);

  requestMessage.onload = function() {
    if (requestMessage.status >= 200 && requestMessage.status < 400){
        var etag = requestMessage.getResponseHeader("ETag");
        if(sessionStorage.getItem("cachedEtagMsg") != etag || neverDrawn){
            sessionStorage.setItem("cachedEtagMsg", etag);
            data = JSON.parse(requestMessage.responseText);
            callback(data, execNewEvent);
        }
    } else{
        console.log("request status"+requestMessage.status);
    }
  };

  requestMessage.onerror = function() {
    console.log("request error");
  };

  requestMessage.send();
}


function loadHTMLMessages(object, execNewEvent){
  $("#notifs").empty();
  $("#notifs").append('<h2>INFOS</h2>');
  object.forEach(function(notif) {
    date = new Date(notif.time*1000);
    strdate = date.getFullYear() + "-" + (date.getMonth()+1) + "-" + date.getDate() + " | " + date.getHours() + ":" + date.getMinutes();
    $("#notifs").append($("#template-notifs").html().replace('#title#',notif.title).replace("#text#",notif.msg).replace("#ts#",strdate) );
  });
}

window.addEventListener('load', function(){
    getMessages(loadHTMLMessages, false, true);
    window.setInterval(function () { if(Focus) { getMessages(loadHTMLMessages, true, false)} }, 5000);
});