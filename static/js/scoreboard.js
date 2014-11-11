function getScoreboard(callback){
  request = new XMLHttpRequest();
  request.open('GET', '/getScoreboard', true);

  request.onload = function() {
    if (request.status >= 200 && request.status < 400){
      data = JSON.parse(request.responseText);
      callback(data);
    } else {
      //
    }
  };

  request.onerror = function() {
    //
  };

  request.send();
}

function extractName(solvedTask){
  return Object.keys(solvedTask)[0];
}

function genCase(line, task, size){
  var hcase = document.createElement("div");
  hcase.classList.add("l-box");
  hcase.classList.add("pure-u-1-"+size);
  var pcontent = document.createElement("p");
  var content = document.createTextNode(task);
  pcontent.appendChild(content);
  hcase.appendChild(pcontent);
  line.appendChild(hcase);
}

function genTaskCase(line, task, solvedTasks, size){
  var bcase = document.createElement("div");
  bcase.classList.add("l-box");
  bcase.classList.add("pure-u-1-"+size);
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
  genCase(header, "Score", arrayTasks.length+2);
  arrayTasks.map(function(x) { return genCase(header, x, arrayTasks.length+2); })
  body.appendChild(header);
}

function genScoreboard(body, team, tasks){
  var line = document.createElement("div");
  line.classList.add("pure-g");
  genCase(line, '#'+team.pos+' - '+team.team, tasks.length+2);
  genCase(line, team.score, tasks.length+2);
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

getScoreboard(loadHTMLScoreboard);
window.setInterval(function () {getScoreboard(loadHTMLScoreboard)}, 5000);
