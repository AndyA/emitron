var picture1 = "wembleyplansmalldark.png";
var picture2 = "wembleyplansmall.png";
if (document.images) {
 image1 = new Image();
 image1.src = picture1
 image2 = new Image();
 image2.src = picture2;
}
function mover(img){
 document["change"].src = img.src;



}
function mout(img){
 document["change"].src = img.src;
}

    var audio1 = new Audio();
    var audio2 = new Audio();
    var audio3 = new Audio();

    
    if (/MSIE (\d+\.\d+);/.test(navigator.userAgent) || /Safari (\d+\.\d+);/.test(navigator.userAgent)){
	
    audio1.setAttribute('src', 'http://ic.prototype0.net:8000/radio1.mp3');
    audio1.setAttribute('type', 'audio/mpeg');

    audio2.setAttribute('src', 'http://ic.prototype0.net:8000/radio2.mp3');
    audio2.setAttribute('type', 'audio/mpeg');

    audio3.setAttribute('src', 'http://ic.prototype0.net:8000/radio5l.mp3');
    audio3.setAttribute('type', 'audio/mpeg');
	}

	else {
    audio1.setAttribute('src', 'http://ic.prototype0.net:8000/radio1.ogg');
    audio1.setAttribute('type', 'audio/ogg');

    audio2.setAttribute('src', 'http://ic.prototype0.net:8000/radio2.ogg');
    audio2.setAttribute('type', 'audio/ogg');

    audio3.setAttribute('src', 'http://ic.prototype0.net:8000/radio5l.ogg');
    audio3.setAttribute('type', 'audio/ogg');
	}
 
    audio1.volume = 0.25;
    audio2.volume = 0.25;
    audio3.volume = 0.5;


    var click = 0;




function timecodechecker(){
console.log("This is being called");
console.log("Time of track A " + audio1.currentTime);
console.log("Time of track B " + audio2.currentTime);
console.log("Time of track C " + audio3.currentTime);


update();

/*
var minTime = audio1.currentTime;
var minTimeSource = 1;
if (audio2.currentTime<audio1.currentTime){
minTime = audio2.currentTime;
var minTimeSource = 2;
}
else if (audio3.currentTime<minTime){
minTime = audio3.currentTime;
var minTimeSource = 3;
}


if(audio1.currentTime != audio2.currentTime || audio1.currentTime != audio3.currentTime || audio2.currentTime != audio3.currentTime && click != 0){

if(minTimeSource == 1){

var differenceA = 1000*(audio2.currentTime-minTime);
var differenceB = 1000*(audio3.currentTime-minTime);

if (differenceA > 100 || differenceB > 100){
audio2.pause();
setTimeout(function(){audio2.play()}, differenceA);
audio3.pause();
setTimeout(function(){audio3.play()}, differenceB);
}

}

if(minTimeSource == 2){

var differenceA = 1000*(audio1.currentTime-minTime);
var differenceB = 1000*(audio3.currentTime-minTime);

if (differenceA > 100 || differenceB > 100){
audio1.pause();
setTimeout(function(){audio1.play()}, differenceA);
audio3.pause();
setTimeout(function(){audio3.play()}, differenceB);
}

}

if(minTimeSource == 3){

var differenceA = 1000*(audio1.currentTime-minTime);
var differenceB = 1000*(audio2.currentTime-minTime);

if (differenceA > 100 || differenceB > 100){
audio2.pause();
setTimeout(function(){audio2.play()}, differenceA);
audio1.pause();
setTimeout(function(){audio1.play()}, differenceB);
}

}



}

*/


}

function update(){

 setTimeout(function() {timecodechecker();}, 5000);

}




function play(){
        timecodechecker();
	try {
      	audio1.play();
	console.log("playing 1 schnorbitz");
	console.log("audio 1: " + audio1.networkState);
	console.log("audio 1 error: " + audio1.error.code);
   	} catch ( e ) {
      	console.log("Error: " + e.description );
   	}
	try {
      	audio2.play();
	console.log("playing 2");
	console.log("audio 2: " + audio2.networkState);
	console.log("audio 2 error: " + audio2.error.code);
   	} catch ( e ) {
      	console.log("Error: " + e.description );
   	}
	try {
      	audio3.play();
	console.log("playing 3");
	console.log("audio 3: " + audio3.networkState);
	console.log("audio 3 error: " + audio3.error.code);
   	} catch ( e ) {
      	console.log("Error: " + e.description );
   	}
        //	audio1.play();
	//   	
	//	audio2.play();
		
	//	audio3.play();
		
	   };

function pause(){
        console.log("pausing");
	   	audio1.pause();
	   	audio2.pause();
        	audio3.pause();
        };

var balancebar, slider3, balancebar2, slider2;

        load = function(){
	
	try {
      	audio1.load();
	console.log("audio 1: " + audio1.networkState);
   	} catch ( e ) {
      	console.log("Error: " + e.description );
   	}
	try {
      	audio2.load();
	console.log("audio 2: " + audio2.networkState);
   	} catch ( e ) {
      	console.log("Error: " + e.description );
   	}
	try {
      	audio3.load();
	console.log("audio 3: " + audio3.networkState);
   	} catch ( e ) {
      	console.log("Error: " + e.description );
   	}
        
     //   	audio1.load();
	//	audio2.load();
	//	audio3.load();
	console.log("loaded");
	   };







    var init = function(){
	load();
        
 // Probably an audio cache problem. If you open the browser from scratch - no probs. If you then refresh, only one stream.

	bar = document.getElementById('bar');
	slider = document.getElementById('slider');
	slider.style.width = 75 + '%';
	info = document.getElementById('info');
	bar.addEventListener('mousedown', startSlide, false);	
	bar.addEventListener('mouseup', stopSlide, false);
	balancebar = document.getElementById('balancebar');
	balancebar2 = document.getElementById('balancebar2');
	slider3 = document.getElementById('slider3');
	slider2 = document.getElementById('slider2');
	slider3.style.width = 100 + '%';
	info3 = document.getElementById('info3');
	balancebar.addEventListener('mousedown', startSlide3, false);	
	balancebar.addEventListener('mouseup', stopSlide3, false);
	balancebar2.addEventListener('mousedown', startSlide2, false);	
	balancebar2.addEventListener('mouseup', stopSlide2, false);
    	info.innerHTML = '75%';
	info3.innerHTML = 'equally balanced';
    }




function changeImage() {
//console.log("we are calling this function here");
console.log("click = " + click);



        if (click == 0) 
        {
        //    point_it(event);
		 
            play();
		 
		 document.getElementById("imgName").src = "/sandbox/5live/wembleyplansmall.png";
            click = 1;
            

	       
            console.log("click = " + click);
        }
	   else if (click == 1) 
        {
            document.getElementById("imgName").src = "/sandbox/5live/wembleyplansmall.png";
            TopX = pos_x;
  //          TopY = pos_y;
            click = 2;
            console.log("click = " + click);

        }
        else
        {
            pause();
            document.getElementById("imgName").src = "/sandbox/5live/wembleyplansmalldark.png";
	       click = 0;
            console.log("click = " + click);

        }
    }

var MasterVolume = (2*audio1.volume + 2*audio2.volume + audio3.volume)/2;
//console.log("MasterVolume = " + MasterVolume);
var xV = audio1.volume/MasterVolume;
//console.log("xV = " + xV);
var yV = audio2.volume/MasterVolume;
//console.log("yV = " + yV);
var zV = audio3.volume/MasterVolume;
//console.log("zV = " + zV);
var oldMasterVolume = 0.75;

var percentage;

var set_perc;


function startSlide(event){
	set_perc = ((((event.clientX - bar.offsetLeft) / bar.offsetWidth)).toFixed(2));
	var percentaged = Math.round(set_perc*100);
	updateVolume();
	info.innerHTML = percentaged + '%';			
	bar.addEventListener('mousemove', moveSlide, false);	
	slider.style.width = (set_perc * 100) + '%';	
}
 
function moveSlide(event){
	set_perc = ((((event.clientX - bar.offsetLeft) / bar.offsetWidth)).toFixed(2));
	var percentaged = Math.round(set_perc*100);
	updateVolume();
	info.innerHTML = percentaged + '%';
	slider.style.width = (set_perc * 100) + '%';
}
 
function stopSlide(event){
	set_perc = ((((event.clientX - bar.offsetLeft) / bar.offsetWidth)).toFixed(2));
	var percentaged = Math.round(set_perc*100);
	updateVolume();
	info.innerHTML = percentaged + '%';
	bar.removeEventListener('mousemove', moveSlide, false);
	slider.style.width = (set_perc * 100) + '%';
}


function updateVolume() {

	console.log("MasterVolume = " + MasterVolume);
	MasterVolume = set_perc;
	console.log("set_perc = " + set_perc);
	console.log("xV = " + xV);
	audio1.volume = xV*MasterVolume;
	console.log("audio1.volume = " + audio1.volume);
	audio2.volume = yV*MasterVolume;
	console.log("audio2.volume = " + audio2.volume);
	audio3.volume = zV*MasterVolume;
	console.log("audio3.volume = " + audio3.volume);
	oldMasterVolume = MasterVolume;
}

function startSlide3(event){
	
	var set_perc = ((((event.clientX - balancebar.offsetLeft) / balancebar.offsetWidth)).toFixed(2));
	percentage = -Math.round(100-set_perc*100);
	commentaryBalance();
	updateBalance();
	if (percentage !=0){
	info3.innerHTML = 'more commentary';
	}
	else {
	info3.innerHTML = 'equally balanced';
	}	
	balancebar.addEventListener('mousemove', moveSlide3, false);
	slider2.style.width = 0 + '%';	
	slider3.style.width = (set_perc * 100) + '%';
}

function startSlide2(event){

	var set_perc2 = ((((event.clientX - balancebar2.offsetLeft) / balancebar2.offsetWidth)).toFixed(2));	
	balancebar2.addEventListener('mousemove', moveSlide2, false);
	percentage = Math.round(set_perc2*100);
	commentaryBalance();
	updateBalance();
	if (percentage !=0){
	info3.innerHTML = 'more crowd';
	}
	else {
	info3.innerHTML = 'equally balanced';
	}
	slider3.style.width = 100 + '%';
	slider2.style.width = (set_perc2 * 100) + '%';
}
 
function moveSlide3(event){

	var set_perc = ((((event.clientX - balancebar.offsetLeft) / balancebar.offsetWidth)).toFixed(2));
	percentage = -Math.round(100-set_perc*100);
	commentaryBalance();
	updateBalance();
	if (percentage !=0){
	info3.innerHTML = 'more commentary';
	}
	else {
	info3.innerHTML = 'equally balanced';
	}
	slider2.style.width = 0 + '%';	
	slider3.style.width = (set_perc * 100) + '%';
}
 
function moveSlide2(event){

	var set_perc2 = ((((event.clientX - balancebar2.offsetLeft) / balancebar2.offsetWidth)).toFixed(2));
	percentage = Math.round(set_perc2*100);
	commentaryBalance();
	updateBalance();
	if (percentage !=0){
	info3.innerHTML = 'more crowd';
	}
	else {
	info3.innerHTML = 'equally balanced';
	}
	slider3.style.width = 100 + '%';
	slider2.style.width = (set_perc2 * 100) + '%';
}
 
function stopSlide3(event){

	var set_perc = ((((event.clientX - balancebar.offsetLeft) / balancebar.offsetWidth)).toFixed(2));
	percentage = -Math.round(100-set_perc*100);
	commentaryBalance();
	updateBalance();
	if (percentage !=0){
	info3.innerHTML = 'more commentary';
	}
	else {
	info3.innerHTML = 'equally balanced';
	}
	slider2.style.width = 0 + '%';	
	balancebar.removeEventListener('mousemove', moveSlide3, false);		
	slider3.style.width = (set_perc * 100) + '%';
}
 
function stopSlide2(event){

	var set_perc2 = ((((event.clientX - balancebar2.offsetLeft) / balancebar2.offsetWidth)).toFixed(2));
	percentage = Math.round(set_perc2*100);
	commentaryBalance();
	updateBalance();
	if (percentage !=0){
	info3.innerHTML = 'more crowd';
	}
	else {
	info3.innerHTML = 'equally balanced';
	}
	slider3.style.width = 100 + '%';
	balancebar2.removeEventListener('mousemove', moveSlide2, false);	
	slider2.style.width = (set_perc2 * 100) + '%';
}


function commentaryBalance() {
	
	var crowdBias = xV/(xV+yV);
	audio1.volume = (2*MasterVolume/3+percentage*MasterVolume/600)*crowdBias;
//	console.log("xV = " + xV);
//	console.log("MasterVolume = " + MasterVolume);
//	console.log("percentage = " + percentage);
	console.log("audio1.volume = " + audio1.volume);
	audio2.volume = (2*MasterVolume/3+percentage*MasterVolume/600)*(1-crowdBias);
	console.log("audio2.volume = " + audio2.volume);
	audio3.volume = 2*MasterVolume/3-percentage*MasterVolume/300;
	console.log("audio3.volume = " + audio3.volume);
	updateBalance();
	
}


function updateBalance() {

	xV = audio1.volume/MasterVolume;
//	console.log("audio1.volume = " + audio1.volume);
//	console.log("xV = " + xV);
	yV = audio2.volume/MasterVolume;
//	console.log("audio2.volume = " + audio2.volume);
//	console.log("yV = " + yV);
	zV = audio3.volume/MasterVolume;
//	console.log("audio3.volume = " + audio3.volume);
//	console.log("zV = " + zV);

}

function crowdBalance(xRatio) {

	audio1.volume = (1-xRatio)*MasterVolume*2/3;
//	console.log("audio1.volume = " + audio1.volume);
	audio2.volume = (xRatio)*MasterVolume*2/3;
//	console.log("audio2.volume = " + audio2.volume);
	updateBalance();

}






/*
function point_it(event){

var event;
    pos_x = event.offsetX?(event.offsetX):event.pageX-document.getElementById("imgName").offsetLeft;
    pos_y = event.offsetY?(event.offsetY):event.pageY-document.getElementById("imgName").offsetTop;
//    console.log("pos_x " + pos_x);
//    console.log("pos_y " + pos_y);

if (click == 2)
{
pos_x = TopX;
//pos_y = TopY;

}

xRatio=(pos_x)/648;
x=xRatio * 100;


yRatio=(181-pos_y)*(181-pos_y)/182/182;
y=yRatio * 100;
//document.getElementById("xycoordinates").innerHTML="Coordinates: (" + x1 + "," + y1 + ")";

var ratio = xRatio
// Use an equal-power crossfading curve:
//audio1.volume = Math.cos(xRatio * 0.5*Math.PI);
audio1.volume = 1-xRatio;
// console.log("audio1.volume " + audio1.volume);

//audio2.volume = Math.cos((1.0 - xRatio) * 0.5*Math.PI);
audio2.volume = xRatio;
//console.log("audio2.volume " + audio2.volume);
//audio3.volume = Math.cos(yRatio * 0.5*Math.PI);
audio3.volume = 1-yRatio;
//console.log("audio3.volume " + audio3.volume);



}
*/