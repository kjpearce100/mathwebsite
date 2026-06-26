/*
EarthQuake script- © Dynamic Drive (www.dynamicdrive.com)
For full source code, installation instructions, 100's more DHTML scripts, and Terms Of Use, 
Visit http://dynamicdrive.com
*/

//configure the likelihood that an earthquake will occur (100% means always)
var chance_of_occurence="5%"

/////do NOT edit below this line/////////////

//variable used to store the equivalency of the 10 rector scales (in the form of 1, 3, 6...etc)
var rectorscale=new Array(1,3,6,9,12,15,18,21,24,27)
chance_of_occurence=parseInt(chance_of_occurence)

function earthquake(){
//randomly assign a number from 1 to 10 to variable rectorindex
rectorindex=Math.floor(Math.random()*10)
//randomly assign one of element rectorscale into variable rector
rector=rectorscale[rectorindex]
if ((document.all||document.layers)&&Math.floor(Math.random()*100)<=chance_of_occurence) {
//shake the browser's screen according to the random rector scale!
for (i=0;i,i<20;i++){
window.moveBy(0,rector)
window.moveBy(rector,0)
window.moveBy(0,-rector)
window.moveBy(-rector,0)
}
// show quake message
quakealert()
}
}

if (document.all)
document.write('<div id="quakenotice_ie"></div>')

function quakealert(){
var quakemessage='An earthquake of magnitude <b>'+eval(rectorindex+1)+'</b> has just occured! Please stay calm ... the tremors are subsiding.'

if (document.all){
quakemsg_ie=document.all.quakenotice_ie
quakemsg_ie.innerHTML=quakemessage
//position quake message in center of screen
quakemsg_ie.style.left=document.body.scrollLeft+document.body.clientWidth/2-quakemsg_ie.offsetWidth/2
quakemsg_ie.style.top=document.body.scrollTop+document.body.clientHeight/2-quakemsg_ie.offsetHeight/2
quakemsg_ie.style.visibility="visible"
setTimeout("quakemsg_ie.style.visibility='hidden'",5000)
}
else if (document.layers){
quakemsg_ns=document.quakenotice_ns
quakemsg_ns.document.write(quakemessage)
quakemsg_ns.document.close()
quakemsg_ns.left=pageXOffset+window.innerWidth/2-quakemsg_ns.document.width/2
quakemsg_ns.top=pageYOffset+window.innerHeight/2-quakemsg_ns.document.height/2
quakemsg_ns.visibility="show"
setTimeout("quakemsg_ns.visibility='hide'",5000)
}
}
