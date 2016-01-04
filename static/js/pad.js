function viewport() {
  var e = window
  var a = 'inner';
  if ( !( 'innerWidth' in window ) ){
    a = 'client';
    e = document.documentElement || document.body;
  }
  return { width : e[ a+'Width' ] , height : e[ a+'Height' ] }
}

var solved = [];

var images = {};
function loadImages(callback) {
    var sources = {
      background: 'background.png',
      cat_box_normal: 'cat_box_normal.png',
      cat_box_pwned: 'cat_box_pwned.png',
      cat_box_used: 'cat_box_used.png',
      coffee_maker_normal: 'coffee_maker_normal.png',
      coffee_maker_pwned: 'coffee_maker_pwned.png',
      coffee_maker_used: 'coffee_maker_used.png',
      fridge_normal: 'fridge_normal.png',
      fridge_pwned: 'fridge_pwned.png',
      fridge_used: 'fridge_used.png',
      plant_normal: 'plant_normal.png',
      plant_pwned: 'plant_pwned.png',
      plant_used: 'plant_used.png',
      sex_toy_normal: 'sex_toy_normal.png',
      sex_toy_pwned: 'sex_toy_pwned.png',
      sex_toy_used: 'sex_toy_used.png',
      toaster_normal: 'toaster_normal.png',
      toaster_pwned: 'toaster_pwned.png',
      toaster_used: 'toaster_used.png'
    }
    var loadedImages = 0;
    var numImages = 0;
    var src;
    for(src in sources) {
        numImages++;
    }
    for(src in sources) {
      images[src] = new Image();
      images[src].onload = function() {
          if(++loadedImages >= numImages) {
              callback(images);
          }
      };
      images[src].src = StaticRoot+'/img/IOTRoom/'+sources[src];
    }
}

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
        solved = data.solved;
        redraw();
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

var objects = {
  cat_box:{
    width: 133,
    height: 79,
    x: 792,
    y: 364
  },
  coffee_maker:{
    width: 66,
    height: 70,
    x: 318,
    y: 257
  },
  fridge:{
    width: 280,
    height: 445,
    x: 13,
    y: 120
  },
  plant:{
    width: 71,
    height: 114,
    x: 628,
    y: 218
  },
  sex_toy:{
    width: 92,
    height: 104,
    x: 608,
    y: 531
  },
  toaster:{
    width: 76,
    height: 65,
    x: 564,
    y: 333
  },
};

var coeff = 1;
var used = '';
var clicked = '';

function getTaskName(special){
  for(var i = 0; i < Tasks.length; i++){
    if(special === Tasks[i].special){
      return Tasks[i].name;
    }
  }
}

function redraw(){
  var can = document.getElementById('IOTRoom');
  var ctx = can.getContext('2d');
  ctx.drawImage(images['background'], 0, 0, can.width, can.height);

  for(var key in objects){
    var n = -1;
    if((n = solved.map(extractName).indexOf(getTaskName(key))) !== -1){
      ctx.drawImage(images[key+'_pwned'], 0, 0, can.width, can.height);
    }
    else{
      if(key === used || key === clicked){
        ctx.drawImage(images[key+'_used'], 0, 0, can.width, can.height);
      }
      else{
        ctx.drawImage(images[key+'_normal'], 0, 0, can.width, can.height);
      }
    }
  }
}

function move(evt, can, click){
  var rect = can.getBoundingClientRect();
  var x = evt.clientX - rect.left;
  var y = evt.clientY - rect.top;
  // var object = objects[Tasks[i]['special']];
  used = '';
  can.style.cursor = 'auto';
  for(var key in objects){
    if(x > objects[key].x*coeff && x < objects[key].x*coeff+objects[key].width*coeff && y > objects[key].y*coeff && y < objects[key].y*coeff+objects[key].height*coeff){
      used = key;
      can.style.cursor = 'pointer';
      if(click){
        clicked = key;
        taskInfos(key);
      }
      break;
    }
  }

  redraw();
}

function start(){
  if(typeof(StaticRoot) === 'undefined'){
    setTimeout(start, 10);
  }
  else{
    loadImages(function(images){
      window.onresize = function(){
        var can = document.getElementById("IOTRoom");
        var windowSize = viewport();
        can.width = windowSize.width-416;
        can.height = can.width*0.68;
        if(can.width*0.68 > windowSize.height-75){
          can.height = windowSize.height-75;
          can.width = can.height/0.68;
        }
        coeff = can.width/1024;
        redraw();
      }

      var can = document.getElementById("IOTRoom");
      var exit = document.getElementById("exit");
      exit.addEventListener("click", function(){
        close();
      });

      can.addEventListener('mousemove', function(evt){ move(evt, can); });
      can.addEventListener('click', function(evt){ move(evt, can, true); });

      var windowSize = viewport();
      can.width = windowSize.width-400;
      can.height = can.width*0.68;
      if(can.width*0.68 > windowSize.height-75){
        can.height = windowSize.height-75;
        can.width = can.height/0.68;
      }
      coeff = can.width/1024;
      refreshScore(true);
      window.setInterval(function () { if(Focus) { refreshScore(false)} }, 1000*60);
    });
  }
}

window.addEventListener('load', function(){
  start();
});

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

function extractName(solvedTask){
  return solvedTask.name;
}

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

function taskInfos(taskSpecial){
  for(var i = 0; i < Tasks.length; i++){
    if(Tasks[i].special === taskSpecial){
      var infos = Tasks[i];
      break;
    }
  }
  document.getElementById('hideshow').style.visibility = 'visible';
  var divInfos = document.getElementById("infosTask");
  divInfos.children[1].children[0].textContent = infos.name+' - '+infos.type+' - '+infos.value+' pts - realized by '+infos.author;
  var flag = document.getElementById("flag")
  flag.value="";
  flag.focus();
  divInfos.children[2].innerHTML = infos.description;
  divInfos.children[4].value = infos.name;
}


function close(){
  var divInfos = document.getElementById("infosTask");
  divInfos.children[0].innerHTML = "";
  document.getElementById('hideshow').style.visibility='hidden';
  clicked = '';
  redraw();
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
