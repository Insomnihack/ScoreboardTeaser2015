function isInfos(child){
  return (child.className=="task-infos");
}

function extractName(solvedTask){
  return solvedTask.name;
}

function extractEvent(solvedArray, taskName){
  var ret = "";
  for(i=0;i<solvedArray.length; i++){
    if(taskName == solvedArray[i].name){
      ret = solvedArray[i].event;
    }
  }
  return ret;
}

function solveTask(task, event, infos){
  task.removeEventListener("click", taskInfos, false);
  infos.event = event;
  console.log(JSON.stringify(infos));
  console.log(task);
  task.children[2].textContent=JSON.stringify(infos);
  task.addEventListener("click", solvedEvent, false);
  task.classList.add("solved-button");
  task.classList.remove("task-button");
}

function refreshScore(callback){
  request = new XMLHttpRequest();
  request.open('GET', '/getScore', true);

  request.onload = function() {
    if (request.status >= 200 && request.status < 400){
      data = JSON.parse(request.responseText);
      document.getElementById("score").textContent=data.score+"PTS"
      var tasks = document.getElementsByClassName("task-button");
      for(i=0;i<tasks.length;i++){
        var infos = JSON.parse(tasks[i].children[2].textContent);
        if(data.solved.map(extractName).indexOf(infos.name)!=-1){
          callback(tasks[i], extractEvent(data.solved, infos.name), infos);
        }
      }
    } else {
      //
    }
  };

  request.onerror = function() {
    //
  };

  request.send();
}

function taskInfos(){
  var infos = JSON.parse(this.children[2].textContent);
  document.getElementById('hideshow').style.visibility = 'visible';
  var divInfos = document.getElementById("infosTask");
  divInfos.children[1].textContent = infos.name;
  var flag = document.getElementById("flag")
  flag.value="";
  flag.focus();
  divInfos.children[2].textContent = infos.description;
  divInfos.children[4].value = infos.name;
}

function submitFlag(){
  var flag = document.getElementById("flag").value;
  var taskname = document.getElementById("taskname").value;

  var request = new XMLHttpRequest();
  request.open('POST', '/submitFlag/'+encodeURIComponent(taskname), true);
  request.onload = function() {
    if (request.status >= 200 && request.status < 400){
      data = JSON.parse(request.responseText);
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

  request.onerror = function() {
    //
  };

  request.send(flag);
}

function solvedEvent(){
  var infos = JSON.parse(this.children[2].textContent);
  eval(infos.event);
}

var tasks = document.getElementsByClassName("task-button");
var solved = document.getElementsByClassName("solved-button");
var exit = document.getElementById("exit");
var submit = document.getElementById("submitFlag");
submit.addEventListener("click", submitFlag, false);
exit.addEventListener("click", function(){ document.getElementById('hideshow').style.visibility='hidden';}, false);

for(i=0;i<tasks.length;i++){
  tasks[i].addEventListener("click", taskInfos, false);
}

for(i=0;i<solved.length;i++){
  solved[i].addEventListener("click", solvedEvent, false);
}

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