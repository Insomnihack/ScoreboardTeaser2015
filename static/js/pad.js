$("#in-screen").delegate('.challenges', 'click', function() {
  var id = $(this).data('challid');
  var infos = Tasks[id];
  document.getElementById('hideshow').style.visibility = 'visible';
  var divInfos = document.getElementById("infosTask");
  divInfos.children[1].children[0].textContent = infos.name+' - '+infos.type+' - '+infos.value+' pts - created by '+infos.author;
  var flag = document.getElementById("flag")
  flag.value="";
  flag.focus();
  divInfos.children[2].innerHTML = infos.description;
  divInfos.children[4].value = infos.name;
});

$('#in-screen').perfectScrollbar();
$('#notifs').perfectScrollbar();


function refreshScore(neverDrawn){
  requestScore = new XMLHttpRequest();
  requestScore.open('GET', '/getScore', true);
  requestScore.onload = function() {
    if (requestScore.status >= 200 && requestScore.status < 400){
      var etag = requestScore.getResponseHeader("ETag");
      if(sessionStorage.getItem("cachedEtagPad") != etag || neverDrawn){
        sessionStorage.setItem("cachedEtagPad", etag);
        var data = JSON.parse(requestScore.responseText);
        var teamStatus = document.getElementById("teamstatus");
        teamStatus.textContent = data.teamName+" - "+data.score+" PTS";
        data.solved.forEach(function(s) {
          $("a[data-chall='" + s.name +"']").addClass('solved');
        });
        solved = data.solved;
      }
    } else{
        console.log("request status"+requestScore.status);
    }
  };

  requestScore.onerror = function() {
    console.log("request error");
  };

  requestScore.send();
}

window.addEventListener("keydown", function(e){
  if(e.keyCode === 27){
    close();
  }
  else if(e.keyCode === 13){
    if(document.getElementById('hideshow').style.visibility === 'visible'){
      submitFlag();
    }
  }
});

function getTaskIDs(callback){
  requestTaskIDs = new XMLHttpRequest();
  requestTaskIDs.open('GET', '/getTaskIDs', true);
  requestTaskIDs.onload = function() {
    if (requestTaskIDs.status >= 200 && requestTaskIDs.status < 400){
      data = JSON.parse(requestTaskIDs.responseText);
      callback(data);
    } else{
        console.log("request status"+requestTaskIDs.status);
    }
  };

  requestTaskIDs.onerror = function() {
    console.log("request error");
  };

  requestTaskIDs.send();
}

function close(){
  var divInfos = document.getElementById("infosTask");
  divInfos.children[0].innerHTML = "";
  document.getElementById('hideshow').style.visibility='hidden';
  clicked = '';
}


function submitFlag(){
  var flag = document.getElementById("flag").value;
  var taskname = document.getElementById("taskname").value;

  var requestFlag = new XMLHttpRequest();
  requestFlag.open('POST', '/submitFlag/'+encodeURIComponent(taskname), true);
  requestFlag.onload = function() {
    if (requestFlag.status >= 200 && requestFlag.status < 400){
      data = JSON.parse(requestFlag.responseText);
      document.getElementById("flag").value=data.status;
      if(data.status=="ok"){
        close();
        eval(data.event);
        refreshScore(false);
        getScoreboard(loadHTMLScoreboard, false);
      }
    } else {
      //
    }
  };

  requestFlag.onerror = function() {
    //
  };

  requestFlag.send(flag);
}

function getScoreboard(callback, neverDrawn){
  requestScoreboard = new XMLHttpRequest();
  requestScoreboard.open('GET', CacheRoot+GetScoreboardR, true);

  requestScoreboard.onload = function() {
    if (requestScoreboard.status >= 200 && requestScoreboard.status < 400){
        var etag = requestScoreboard.getResponseHeader("ETag");
        if(sessionStorage.getItem("cachedEtagScore") !== etag || neverDrawn){
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

window.onload = function() {
  var exit = document.getElementById("exit");
  exit.addEventListener("click", function(){
    close();
  });
  Tasks.forEach(function(task, id) {
    $("#in-screen").append($("#template-challenge").html().replace('#id#',id).replace('#chall#',task.name).replace('#name#',task.name).replace('#type#',task.type).replace('#points#',task.value));
  });

  getScoreboard(loadHTMLScoreboard, true);
  window.setInterval(function () { if(Focus) { getScoreboard(loadHTMLScoreboard, false) } }, 30*1000);

  refreshScore(true);
  window.setInterval(function () { if(Focus) { refreshScore(false)} }, 1000*60);
}

function loadHTMLScoreboard(object){
  var result = {}
  object.tasks.forEach(function(task) {
    result[task] = {name: task, count: 0};
  })
  object.standings.forEach(function(team) {
    team.taskStats.forEach(function(task) {
      result[Object.keys(task)[0]].count += 1;
    });
  });

  Object.keys(result).forEach(function(task) {
    if (result[task].count < 2) {
      $("a[data-chall='" + task +"'] .chall-solvers").text('('+result[task].count+' solver)');
    } else {
      $("a[data-chall='" + task +"'] .chall-solvers").text('('+result[task].count+' solvers)');
    }

  });
}
