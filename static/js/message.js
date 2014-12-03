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

function genMessage(body, news){
  var m = document.createElement("div");
  m.classList.add("l-box");
  m.classList.add("pure-u-1-4");
  var t = document.createElement("h3");
  t.classList.add("content-subhead");
  var t2 = document.createElement("h4");
  t2.classList.add("content-subhead");
  var i = document.createElement("i");
  i.classList.add("fa");
  i.classList.add("fa-rocket");
  var p = document.createElement("p");
  var d = new Date(news.time*1000);
  var contentTitle = document.createTextNode(news.title);
  var contentDate = document.createTextNode(d.toLocaleString());
  var content = document.createTextNode(news.msg);

  i.appendChild(contentDate);
  t2.appendChild(i);


  t.appendChild(contentTitle);
  m.appendChild(t);
  m.appendChild(t2);

  p.appendChild(content);
  m.appendChild(p);

    if(news.script!=""){
        var b = document.createElement("button");
        b.classList.add("pure-button");
        var bContent = document.createTextNode("Play");
        b.addEventListener("click", function(x) { eval(news.script) }, false)
        b.appendChild(bContent);
        m.appendChild(b);
    }


  body.appendChild(m);
}


function loadHTMLMessages(object, execNewEvent){
  var parent = document.getElementById("pnews");
  var n = document.getElementById("news");
  parent.removeChild(n)
  var news = document.createElement("div");
  news.setAttribute("id","news");
  object.map(function(x){ return genMessage(news, x); });
  parent.appendChild(news);
  var lastNews = document.getElementById("lastnews");
    if(execNewEvent && lastNews.textContent!=object[0].time){
        window.scrollBy(0,200);
        if(object[0].script!=""){
            eval(object[0].script);
        }
    }
  lastNews.textContent = object[0].time;
}

window.addEventListener('load', function(){
    getMessages(loadHTMLMessages, false, true);
    window.setInterval(function () { if(Focus) { getMessages(loadHTMLMessages, true, false)} }, 5000);
});