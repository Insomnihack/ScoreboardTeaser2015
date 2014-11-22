function isInfos(child){
  return (child.className=="task-infos");
}

function extractName(solvedTask){
  return solvedTask.name;
}

function solveTask(task, event, infos){
  task.removeEventListener("click", taskInfos, false);
  infos.event = event;
  task.children[2].textContent=JSON.stringify(infos);
  task.addEventListener("click", solvedEvent, false);
  task.classList.add("solved-button");
  task.classList.remove("task-button");
}

function refreshScore(callback, neverDrawn){
  requestScore = new XMLHttpRequest();
  requestScore.open('GET', '/getScore', true);
  requestScore.onload = function() {
    if (requestScore.status >= 200 && requestScore.status < 400){
      var etag = requestScore.getResponseHeader("ETag");
      if(sessionStorage.getItem("cachedEtagPad") != etag || neverDrawn){
        sessionStorage.setItem("cachedEtagPad", etag);
        data = JSON.parse(requestScore.responseText);
        var teamStatus = document.getElementById("teamstatus");
        teamStatus.textContent=data.teamName+" - "+data.score+"PTS"
        var br1 = document.createElement("br");
        var br2 = document.createElement("br");
        var br3 = document.createElement("br");
        teamStatus.appendChild(br1);
        teamStatus.appendChild(br2);
        var challUser = document.createTextNode("Username : "+data.challUser);
        var challPwd = document.createTextNode("Password : "+data.challPwd);
        teamStatus.appendChild(challUser);
        teamStatus.appendChild(br3);
        teamStatus.appendChild(challPwd);
        var tasks = document.getElementsByClassName("pure-button");
        for(i=0;i<tasks.length;i++){
          var infos = JSON.parse(tasks[i].children[2].textContent);
          if((n=data.solved.map(extractName).indexOf(infos.name))!=-1){
            callback(tasks[i], data.solved[n].event, infos);
          }
        }
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

function taskInfos(){
  var infos = JSON.parse(this.children[2].textContent);
  document.getElementById('hideshow').style.visibility = 'visible';
  var divInfos = document.getElementById("infosTask");
  divInfos.children[1].textContent = infos.name;
  var flag = document.getElementById("flag")
  flag.value="";
  flag.focus();
  divInfos.children[2].innerHTML = infos.description;
  divInfos.children[4].value = infos.name;
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
        document.getElementById('hideshow').style.visibility='hidden';
        eval(data.event);
        refreshScore(solveTask);
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

function solvedEvent(){
  var infos = JSON.parse(this.children[2].textContent);
  eval(infos.event);
}

window.addEventListener('load', function(){
  var tasks = document.getElementsByClassName("task-button");
  var exit = document.getElementById("exit");
  var submit = document.getElementById("submitFlag");
  submit.addEventListener("click", submitFlag, false);
  exit.addEventListener("click", function(){ document.getElementById('hideshow').style.visibility='hidden';}, false);

  for(i=0;i<tasks.length;i++){
    tasks[i].addEventListener("click", taskInfos, false);
  }

  refreshScore(solveTask, true);
  window.setInterval(function () { if(Focus) { refreshScore(solveTask, false)} }, 1000*60);

});

window.addEventListener("keydown", function(e){
  if(e.keyCode === 27){
    document.getElementById('hideshow').style.visibility='hidden';
  }
  else if(e.keyCode === 13){
    if(document.getElementById('hideshow').style.visibility=='visible'){
      submitFlag();
    }
  }
});