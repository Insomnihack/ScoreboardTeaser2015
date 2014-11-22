function getScoreboard(callback, neverDrawn){
  requestScoreboard = new XMLHttpRequest();
  requestScoreboard.open('GET', CacheRoot+GetScoreboardR, true);

  requestScoreboard.onload = function() {
    if (requestScoreboard.status >= 200 && requestScoreboard.status < 400){
        var etag = requestScoreboard.getResponseHeader("ETag");
        if(sessionStorage.getItem("cachedEtagScore") != etag || neverDrawn){
            sessionStorage.setItem("cachedEtagScore", etag);
            data = JSON.parse(requestScoreboard.responseText);
            callback(data);
        }
    } else if(requestScoreboard.status==1 || requestScoreboard.status==0) {
        getScoreboard(callback, neverDrawn);
    } else{
        console.log("requestScoreboard status"+requestScoreboard.status);
    }
  };

  requestScoreboard.onerror = function() {
    console.log("requestScoreboard error");
  };

  requestScoreboard.send();
}

function extractName(solvedTask){
  return Object.keys(solvedTask)[0];
}

function genCase(line, task, size){
  var hcase = document.createElement("div");
  hcase.classList.add("l-box");
  hcase.classList.add("pure-u");
  hcase.classList.add("is-center");
  console.log(size);
  hcase.style.width=1/size*100+"%";
  var pcontent = document.createElement("p");
  var content = document.createTextNode(task);
  pcontent.appendChild(content);
  hcase.appendChild(pcontent);
  line.appendChild(hcase);
}

function genCaseCountry(line, country, size){
  var hcase = document.createElement("div");
  hcase.classList.add("l-box");
  hcase.classList.add("pure-u");
  hcase.classList.add("is-center");
  hcase.style.width=1/size*100+"%";
  var pcontent = document.createElement("p");
  var img = document.createElement('img');
  img.src = StaticRoot+'/img/flags/'+country;
  pcontent.appendChild(img);
  hcase.appendChild(pcontent);
  line.appendChild(hcase);
}

function genTaskCase(line, task, solvedTasks, size){
  var bcase = document.createElement("div");
  bcase.classList.add("l-box");
  bcase.classList.add("pure-u");
  bcase.classList.add("is-center");
  bcase.style.width=1/size*100+"%";
  var pcontent = document.createElement("p");

  if((n=solvedTasks.map(extractName).indexOf(task))!=-1){
    var content = document.createTextNode("solved - " + solvedTasks[n][task].time);
  }
  else{
    var content = document.createTextNode("not solved");
  }

  pcontent.appendChild(content);
  bcase.appendChild(pcontent);
  line.appendChild(bcase);
}

function headerTasks(body, arrayTasks){
  var header = document.createElement("div");
  header.classList.add("pure-g");
  genCase(header, "Teams", arrayTasks.length+2);
  genCase(header, "Country", (arrayTasks.length+2)*2);
  genCase(header, "Score", (arrayTasks.length+2)*2);
  arrayTasks.map(function(x) { return genCase(header, x, arrayTasks.length+2); })
  body.appendChild(header);
}

function genScoreboard(body, team, tasks){
  var line = document.createElement("div");
  line.classList.add("pure-g");
  genCase(line, '#'+team.pos+' - '+team.team, tasks.length+2);
  genCaseCountry(line, team.country, (tasks.length+2)*2);
  genCase(line, team.score, (tasks.length+2)*2);
  tasks.map(function(x) { return genTaskCase(line, x, team.taskStats, tasks.length+2); });
  body.appendChild(line);
}

function loadHTMLScoreboard(object){
  var parent = document.getElementById("parent");
  var s = document.getElementById("scoreboard");
  parent.removeChild(s)
  var scoreboard = document.createElement("div");
  scoreboard.setAttribute("id","scoreboard");
  headerTasks(scoreboard, object.tasks);
  object.standings.map(function(x){ return genScoreboard(scoreboard, x, object.tasks); });
  parent.appendChild(scoreboard);
}

window.addEventListener('load', function(){
  getScoreboard(loadHTMLScoreboard, true);
  window.setInterval(function () { if(Focus) { getScoreboard(loadHTMLScoreboard, false) } }, 5000);
});
