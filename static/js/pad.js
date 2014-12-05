function isInfos(child){
  return (child.className=="task-infos");
}

function extractName(solvedTask){
  return solvedTask.name;
}

function getTaskIDs(path, callback){
  requestTaskIDs = new XMLHttpRequest();
  requestTaskIDs.open('GET', path, true);
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
        var tasks = document.getElementsByClassName("my-pure-button");
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

function closeTV(){
  var divInfos = document.getElementById("infosTask");
  divInfos.children[0].innerHTML = "";
  document.getElementById('hideshow').style.visibility='hidden';
}

function taskInfos(){
  var infos = JSON.parse(this.children[2].textContent);
  document.getElementById('hideshow').style.visibility = 'visible';
  var divInfos = document.getElementById("infosTask");
  divInfos.children[1].children[0].textContent = infos.name+' - '+infos.type+' - '+infos.value+' pts - realised by '+infos.author;
  var flag = document.getElementById("flag")
  flag.value="";
  flag.focus();
  divInfos.children[0].innerHTML = '<iframe id="ytplayer" type="text/html" width="640" height="390" src="'+infos.youtube+'" frameborder="0"/>';
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
        closeTV();
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
  function loadImages(callback) {
  var images = {};
  var sources = {
      logo: 'logo-test.png',
      spot: 'spot.png',
    };
    var loadedImages = 0;
    var numImages = 0;
    for(var src in sources) {
      numImages++;
    }
    for(var src in sources) {
      images[src] = new Image();
      images[src].onload = function() {
          if(++loadedImages >= numImages) {
            callback(images);
          }
      };
    images[src].src = StaticRoot+'/img/'+sources[src];
    }
}


  loadImages(function(images) {
    var canvas = document.getElementById("padcanvas");
    var angles=[0,0];
    var clocks=[true,false];
    var interval=0.5;
    var maxin = 30;
    var maxout = 5;
    var frameinterval = 50;
    var moveSpot = setInterval(function(){
      if(Focus){
        draw(canvas, images, angles);
        for(i=0;i<clocks.length;i++){
          if(clocks[i])
            angles[i]+=interval;
          else
            angles[i]-=interval;
        }
        if(angles[0]>=maxin)
          clocks[0]=0;
      if(angles[0]<=-maxout)
          clocks[0]=1;
        if(angles[1]>=maxout)
          clocks[1]=0;
      if(angles[1]<=-maxin)
          clocks[1]=1;
      }
    }, frameinterval);
  });

  function draw(canvas, images, angles){
    var ctx = canvas.getContext("2d");
    ctx.clearRect(0,0,document.getElementById("padcanvas").width,document.getElementById("padcanvas").height);
    ctx.drawImage(images.logo,0,0);

    var low = 60

    ctx.save();
    ctx.translate(100/2+20,450);
    ctx.rotate(angles[0]*Math.PI/180);
    ctx.drawImage(images.spot,-50,-340);
    ctx.restore();
    ctx.save();
    ctx.translate(100/2+images.logo.width-130,450);
    ctx.rotate(angles[1]*Math.PI/180);
    ctx.drawImage(images.spot,-50,-340);
    ctx.restore();
  }

  var tasks = document.getElementsByClassName("task-button");
  var exit = document.getElementById("exit");
  exit.addEventListener("click", function(){
    closeTV();
  }, false);

  for(i=0;i<tasks.length;i++){
    tasks[i].addEventListener("click", taskInfos, false);
  }

  refreshScore(solveTask, true);
  window.setInterval(function () { if(Focus) { refreshScore(solveTask, false)} }, 1000*60);

});

window.addEventListener("keydown", function(e){
  if(e.keyCode === 27){
    closeTV();
  }
  else if(e.keyCode === 13){
    if(document.getElementById('hideshow').style.visibility=='visible'){
      submitFlag();
    }
  }
});