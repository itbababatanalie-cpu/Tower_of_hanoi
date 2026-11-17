% ============================================================
%  TOWER OF HANOI - SAKURA   (SWI-Prolog server + JavaScript UI)
%  Run:   swipl towerofhanoiSakura.pl     then open http://localhost:8080
%  VS Code: open this file, use the SWI-Prolog extension "Load document"
%           or run the command above in the integrated terminal.
%  Prolog solves the puzzle from ANY peg to ANY peg (Hint + Auto Play).
% ============================================================
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(readutil)).
:- use_module(library(lists)).

:- dynamic self_file/1.
:- prolog_load_context(source, F), assertz(self_file(F)).

:- http_handler(root(.), home, []).
:- http_handler(root(api/solve), solve, []).

:- initialization(start).

start :-
    (   getenv('PORT', PA), atom_number(PA, Port)
    ->  Deploy = true
    ;   Port = 8080, Deploy = false
    ),
    catch(( http_server(http_dispatch, [port(Port)]),
            format("~nSakura Hanoi running on port ~w~n", [Port]),
            (   Deploy == true
            ->  thread_get_message(_)
            ;   (   catch(( use_module(library(www_browser)),
                            format(atom(U), 'http://localhost:~w', [Port]),
                            www_open_url(U) ), _, true)
                ->  true
                ;   true
                )
            ) ),
          E, ( print_message(error, E),
               format("Port ~w busy? Edit Port in start/0.~n", [Port]) )).
% ---- Serve the page: HTML lives in the block comment at file end ----
home(_) :-
    self_file(F),
    read_file_to_string(F, S, []),
    atom_concat('/*', 'HTML-BEGIN', Start),
    atom_concat('HTML-END', '*/', End),
    sub_string(S, B0, L0, _, Start), !,
    B is B0 + L0,
    sub_string(S, B, _, 0, Tail),
    sub_string(Tail, E, _, _, End), !,
    sub_string(Tail, 0, E, _, Html),
    format("Content-type: text/html; charset=UTF-8~n~n"),
    write(Html).

% ---- /api/solve?pos=a,a,a&to=c  (pos = peg of disc 1..N, 1 = smallest) ----
solve(Request) :-
    http_parameters(Request, [pos(P, []), to(T, [])]),
    atomic_list_concat(L, ',', P),
    length(L, N),
    mv(N, T, L, _, Ms),
    reply_json_dict(_{moves: Ms}).

% mv(K, Target, Pos0, Pos, Moves): move discs 1..K onto Target
mv(0, _, P, P, []) :- !.
mv(K, T, P0, P, Ms) :-
    nth1(K, P0, F), K1 is K - 1,
    (   F == T
    ->  mv(K1, T, P0, P, Ms)
    ;   other(F, T, S),
        mv(K1, S, P0, P1, M1),
        nth1(K, P1, _, R), nth1(K, P2, T, R),
        mv(K1, T, P2, P, M2),
        append(M1, [[F, T]|M2], Ms)
    ).

other(F, T, S) :- member(S, [a, b, c]), S \== F, S \== T, !.

/*HTML-BEGIN
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Sakura Hanoi</title>
<style>
*{box-sizing:border-box;margin:0}
body{font-family:Georgia,'Hiragino Mincho ProN',serif;color:#fff;height:100vh;overflow:hidden;--s1:#ffd6e0;--s2:#fff4f0;--ac:#ff8fab;--m1:#9aa9c9;--m2:#c5d0e6}
body[data-m="1"]{--s1:#ff8a3d;--s2:#ffe0a3;--ac:#e8b84a;--m1:#8a5a6a;--m2:#c98a7a}
body[data-m="2"]{--s1:#9edcff;--s2:#f2fbff;--ac:#7fd4ff;--m1:#7f9fc0;--m2:#d8ecff}
body[data-m="3"]{--s1:#0b0714;--s2:#4a1230;--ac:#ff2a4d;--m1:#241a33;--m2:#45304f}
#bg{position:fixed;inset:0;background:linear-gradient(var(--s1),var(--s2))}
#bg svg{width:100%;height:100%;display:block}
#bg path,#bg polygon,#bg rect{transition:fill 1s}
#fx{position:fixed;inset:0;pointer-events:none;z-index:60}
.scr{position:fixed;inset:0;display:none;overflow:auto;padding:18px;z-index:5}
.scr.on{display:block}
.glass{background:rgba(25,12,35,.58);backdrop-filter:blur(10px);border:1px solid rgba(255,255,255,.25);border-radius:18px;box-shadow:0 8px 30px rgba(0,0,0,.35)}
button{font:inherit;font-weight:bold;padding:10px 18px;border:0;border-radius:12px;background:var(--ac);color:#2b0f1a;cursor:pointer;transition:transform .15s}
button:hover{transform:translateY(-2px)}
button.g{background:rgba(255,255,255,.18);color:#fff}
button:disabled{opacity:.4;cursor:default}
input,select{font:inherit;padding:8px 10px;border-radius:10px;border:1px solid #fff5;background:#0006;color:#fff;width:100%}
select option{color:#000}
h1{text-align:center;font-size:clamp(28px,6vw,54px);letter-spacing:4px;text-shadow:0 3px 12px #0008;margin-top:8px}
.sub{text-align:center;opacity:.95;margin:4px 0 18px;text-shadow:0 2px 6px #0008}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:16px;max-width:1150px;margin:0 auto}
.card{padding:14px;cursor:pointer;transition:transform .25s,box-shadow .25s}
.card:hover{transform:translateY(-6px) scale(1.02);box-shadow:0 0 28px var(--c)}
.card h3{letter-spacing:3px}.card small{opacity:.85;display:block;margin:2px 0 8px}
.card .board{height:150px}
.card .row{display:flex;justify-content:space-between;align-items:center;margin-top:8px;font-size:13px}
.bar{display:flex;justify-content:center;gap:10px;margin-top:18px}
.board{position:relative;height:340px;width:100%}
.tower{position:absolute;top:0;bottom:0;width:33.333%;cursor:pointer}
.tower b{position:absolute;bottom:0;width:100%;text-align:center;font-size:13px}
.peg{position:absolute;left:calc(50% - 5px);bottom:28px;width:10px;border-radius:5px 5px 0 0}
.base{position:absolute;left:6%;right:6%;bottom:18px;height:12px;border-radius:6px}
.disc{position:absolute;border-radius:14px;z-index:2;display:flex;align-items:center;justify-content:center;box-shadow:0 4px 6px #0006,inset 0 3px 3px #fff8,inset 0 -4px 5px #0006}
.tower.sel .base,.tower.hint .base{box-shadow:0 0 18px 6px var(--ac)}
.tower.bad{animation:sh .25s}
@keyframes sh{25%{transform:translateX(-8px)}75%{transform:translateX(8px)}}
body.shake #game{animation:sh .2s}
.m0 .peg{background:repeating-linear-gradient(0deg,#79ab55 0 38px,#3f6b2c 38px 42px)}
.m0 .base{background:linear-gradient(#d3a574,#8a5a35)}
.m1 .peg{background:linear-gradient(90deg,#7a1118,#d42a2a,#7a1118);border-top:6px solid #e8b84a}
.m1 .base{background:linear-gradient(#f0c75a,#8a6a1a)}.m1 .disc{border:2px solid #f0c75a}
.m2 .peg{background:linear-gradient(90deg,#cfeaff,#fff,#9fd0f0);box-shadow:0 0 10px #9ef}
.m2 .base{background:linear-gradient(#fff,#8fc0e6)}.m2 .disc{border:1px solid #fffc}
.m3 .peg{background:linear-gradient(90deg,#400,#e0203a,#400);box-shadow:0 0 12px #f24}
.m3 .peg::before{content:'';position:absolute;top:8px;left:-24px;right:-24px;height:9px;background:#c01030;border-radius:3px}
.m3 .base{background:linear-gradient(#444,#000)}.m3 .disc{border:2px solid #ff2a4d;box-shadow:0 0 12px #f24,inset 0 2px 2px #fff3}
.m3 .disc::after{content:'\16B1  \16A2  \16B1';color:#ff4060;text-shadow:0 0 6px #f24;font-size:11px;white-space:nowrap;overflow:hidden;letter-spacing:2px}
#game{display:none}#game.on{display:block}
.wrap{max-width:900px;margin:0 auto}
.hud{display:flex;flex-wrap:wrap;gap:14px;justify-content:space-between;align-items:center;padding:10px 16px;margin-bottom:12px}
.hud span{font-size:18px}
.ctrl{display:flex;flex-wrap:wrap;gap:8px;justify-content:center;margin-top:12px}
#toast{text-align:center;height:24px;margin-top:8px;text-shadow:0 2px 6px #000}
.multi .sp{display:none}
#modal{position:fixed;inset:0;background:#0007;display:none;place-items:center;z-index:50}
#modal.on{display:grid}
.box{padding:24px;width:92%;max-width:460px;text-align:center;max-height:92vh;overflow:auto}
.box h2{margin-bottom:10px;letter-spacing:2px}.box p{margin:6px 0}
.f{text-align:left;margin:8px 0;font-size:14px}
.seg{display:flex;gap:14px;justify-content:center;margin:8px 0}
.seg input{width:auto}
table{width:100%;border-collapse:collapse;margin:10px 0}td,th{padding:4px 6px;border-bottom:1px solid #fff3;font-size:14px}
.err{color:#ff9aa8;min-height:20px;font-size:14px}
#gate{position:fixed;inset:0;z-index:70;display:grid;place-items:center;text-align:center;background:linear-gradient(#ffd6e0,#fff4f0);color:#6b2a3f;cursor:pointer}
#gate h1{color:#c2456b;text-shadow:none}
</style></head><body data-m="0">
<div id="bg"><svg viewBox="0 0 1000 500" preserveAspectRatio="xMidYMax slice">
<polygon fill="var(--m2)" points="0,400 120,230 230,330 360,170 520,360 680,200 820,340 930,240 1000,320 1000,500 0,500"/>
<polygon fill="#fff" opacity=".92" points="360,170 330,215 355,205 375,225 395,205 410,225 385,190"/>
<polygon fill="#fff" opacity=".92" points="120,230 98,262 120,254 140,270 160,250"/>
<polygon fill="#fff" opacity=".92" points="680,200 652,240 678,230 698,248 722,228"/>
<polygon fill="var(--m1)" points="0,440 150,300 300,400 470,280 640,410 800,310 1000,420 1000,500 0,500"/>
<polygon fill="#fff" points="150,300 120,335 150,325 175,345 195,320"/>
<polygon fill="#fff" points="470,280 440,318 470,308 490,330 515,305"/>
<polygon fill="#fff" points="800,310 775,340 800,332 820,348 835,330"/>
<g fill="#2b1a22"><rect x="400" y="395" width="200" height="105"/>
<path d="M330,400 Q500,330 670,400 L640,412 Q500,362 360,412Z"/>
<path d="M410,352 Q500,292 590,352 L576,362 Q500,322 424,362Z"/></g>
<g fill="#b3262e"><rect x="420" y="415" width="14" height="85"/><rect x="480" y="415" width="14" height="85"/><rect x="540" y="415" width="14" height="85"/><rect x="580" y="415" width="10" height="85"/></g>
<rect x="0" y="480" width="1000" height="20" fill="#fff" opacity=".85"/></svg></div>
<canvas id="fx"></canvas>

<div id="gate"><div><h1>SAKURA HANOI</h1><p style="font-size:20px;margin-top:14px">Click to Enable Sound &amp; Enter</p></div></div>

<div id="menu" class="scr">
<h1>SAKURA HANOI</h1><p class="sub">Hover (or tap) a card to preview &middot; click PLAY to start</p>
<div class="cards" id="cards"></div>
<div class="bar"><button class="g" id="bset">Settings</button></div></div>

<div id="game" class="scr"><div class="wrap">
<div class="hud glass"><span id="pname"></span><span id="mname"></span><span class="ht">Moves <b id="mv"></b></span><span class="ht">Time <b id="tm"></b></span></div>
<div class="glass" style="padding:14px"><div class="board" id="gb"></div></div>
<div id="toast"></div>
<div class="ctrl">
<button class="sp" id="brs">Restart</button><button class="sp" id="bun">Undo</button><button class="sp" id="bhi">Hint</button><button class="sp" id="bau">Auto Play</button><button class="sp g" id="bpa">Pause</button><button class="g" id="bset2">Settings</button><button class="g" id="bq">Quit</button>
</div></div></div>
<div id="modal"><div class="box glass" id="mbox"></div></div>

<script>
const $=s=>document.querySelector(s),P=['a','b','c'],sleep=ms=>new Promise(r=>setTimeout(r,ms)),rnd=a=>a[Math.floor(Math.random()*a.length)];
const MODES=[
{name:'EASY',tag:'Calm Sakura Dawn',n:3,bpm:72,sc:[262,294,330,392,440,524],w:'triangle',dec:1.4,dm:0,col:['#ffb7c5','#fff0f3','#ff9bb0'],a:{up:.28,x:.34,e:'ease-in-out',f:'scale(1.1)'}},
{name:'HARD',tag:'Temple Sunset',n:5,bpm:104,sc:[294,349,392,440,523,587],w:'triangle',dec:.5,dm:4,col:['#ffd34d','#ffb02e','#fff2a8'],a:{up:.2,x:.28,e:'cubic-bezier(.3,1.4,.6,1)',f:'rotate(-8deg)'}},
{name:'DIFFICULT',tag:'Snow Blizzard',n:7,bpm:84,sc:[1047,1175,1319,1568,1760],w:'sine',dec:2,dm:0,col:['#ffffff','#bfe9ff','#7fd4ff'],a:{up:.1,x:.22,e:'linear',f:'none',low:1}},
{name:'EXPERT',tag:'Midnight Torii',n:9,bpm:150,sc:[73,87,98,110,131],w:'sawtooth',dec:.35,dm:2,col:['#ff2a4d','#ff8a1e','#ffffff'],a:{up:.07,x:.06,e:'cubic-bezier(.9,0,1,1)',f:'none'}}];
const S=Object.assign({music:.5,sfx:.7,mute:false,petals:2,timer:true,rm:false},(()=>{try{return JSON.parse(localStorage.getItem('hs')||'{}')}catch(e){return{}}})());
const saveS=()=>{try{localStorage.setItem('hs',JSON.stringify(S))}catch(e){}};
/* ---------- AUDIO ---------- */
let AC,MG,SG;
function initAudio(){AC=new(window.AudioContext||window.webkitAudioContext)();MG=AC.createGain();SG=AC.createGain();MG.connect(AC.destination);SG.connect(AC.destination);vol()}
function vol(){if(!AC)return;MG.gain.value=S.mute?0:S.music;SG.gain.value=S.mute?0:S.sfx}
function tone(f,d,ty,v,dest,dl=0){const t=AC.currentTime+dl,o=AC.createOscillator(),g=AC.createGain();o.type=ty;o.frequency.value=f;g.gain.setValueAtTime(v,t);g.gain.exponentialRampToValueAtTime(.001,t+d);o.connect(g);g.connect(dest);o.start(t);o.stop(t+d+.05)}
function drum(dest,big){const t=AC.currentTime,o=AC.createOscillator(),g=AC.createGain();o.frequency.setValueAtTime(big?170:115,t);o.frequency.exponentialRampToValueAtTime(40,t+.3);g.gain.setValueAtTime(big?.9:.5,t);g.gain.exponentialRampToValueAtTime(.001,t+.4);o.connect(g);g.connect(dest);o.start(t);o.stop(t+.45);
const nb=AC.createBuffer(1,AC.sampleRate*.12,AC.sampleRate),d=nb.getChannelData(0);for(let i=0;i<d.length;i++)d[i]=(Math.random()*2-1)*(1-i/d.length);const s=AC.createBufferSource(),ng=AC.createGain();s.buffer=nb;ng.gain.value=big?.35:.15;s.connect(ng);ng.connect(dest);s.start(t)}
function sfx(mi){if(!AC)return;const d=SG;
if(mi==0){tone(196,.14,'triangle',.8,d);tone(392,.08,'sine',.2,d)}
else if(mi==1){tone(880,1,'sine',.5,d);tone(1320,.7,'sine',.25,d);tone(1760,.4,'sine',.1,d)}
else if(mi==2){tone(2093,.6,'triangle',.4,d);tone(3136,.35,'sine',.2,d)}
else drum(d,1)}
function bad(){if(AC)tone(110,.25,'sawtooth',.4,SG)}
function winSnd(){if(AC)[523,659,784,1047].forEach((f,i)=>tone(f,.8,'triangle',.4,SG,i*.15))}
const music={t:null,g:null,k:2,st:0,
start(i,v){this.stop();if(!AC)return;const m=MODES[i];this.g=AC.createGain();this.g.gain.value=v;this.g.connect(MG);this.st=0;
this.t=setInterval(()=>{this.st++;this.k=Math.max(0,Math.min(m.sc.length-1,this.k+Math.floor(Math.random()*5)-2));
if(this.st%2==0||i>1)tone(m.sc[this.k],m.dec,m.w,.2,this.g);
if(m.dm&&this.st%m.dm==0)drum(this.g,this.st%(m.dm*4)==0);
if(i==2&&this.st%8==0)tone(110,3,'sawtooth',.04,this.g);
if(i==2&&Math.random()<.2)tone(2400,1.5,'sine',.08,this.g)},30000/m.bpm)},
stop(){clearInterval(this.t);const g=this.g;if(g){g.gain.setTargetAtTime(0,AC.currentTime,.15);setTimeout(()=>g.disconnect(),700)}this.g=null}};
/* ---------- FX: petals + particles ---------- */
const cv=$('#fx'),cx=cv.getContext('2d');let PL=[],PT=[];
const rs=()=>{cv.width=innerWidth;cv.height=innerHeight};addEventListener('resize',rs);rs();
function initPetals(){const n=[0,25,55,100][S.petals];PL=[];for(let i=0;i<n;i++)PL.push({x:Math.random()*cv.width,y:Math.random()*cv.height,s:4+Math.random()*6,vy:.6+Math.random()*1.2,ph:Math.random()*6,r:Math.random()*6,vr:(Math.random()-.5)*.05,c:rnd(['#ffc2d1','#ffb3c6','#fff0f5','#ff9bb0'])})}
function burst(x,y,mi){const c=MODES[mi].col,k=S.rm?10:mi==3?34:26;
for(let i=0;i<k;i++)PT.push({x,y,vx:(Math.random()-.5)*(mi==3?9:5),vy:-Math.random()*4-1,l:1,s:2+Math.random()*(mi==0?5:3),c:rnd(c),g:mi==2?.04:.12});
if(mi>=2)PT.push({ring:1,x,y,r:5,l:1,c:c[2]});
if(mi==3&&!S.rm){const p=[[x+(Math.random()-.5)*60,0]];for(let j=1;j<9;j++)p.push([x+(Math.random()-.5)*50,y*j/8]);p.push([x,y]);PT.push({bolt:p,l:1})}}
function frame(){cx.clearRect(0,0,cv.width,cv.height);const sp=S.rm?.4:1;
for(const p of PL){p.y+=p.vy*sp;p.ph+=.02;p.x+=Math.sin(p.ph)*.6+.5*sp;p.r+=p.vr;if(p.y>cv.height+20){p.y=-20;p.x=Math.random()*cv.width}if(p.x>cv.width+30)p.x=-30;
cx.save();cx.translate(p.x,p.y);cx.rotate(p.r);cx.fillStyle=p.c;cx.globalAlpha=.85;cx.beginPath();cx.ellipse(0,0,p.s,p.s*.55,0,0,7);cx.fill();cx.restore()}
PT=PT.filter(p=>p.l>0);for(const p of PT){cx.globalAlpha=Math.max(0,p.l);
if(p.ring){p.r+=6;p.l-=.04;cx.strokeStyle=p.c;cx.lineWidth=3;cx.beginPath();cx.arc(p.x,p.y,p.r,0,7);cx.stroke()}
else if(p.bolt){p.l-=.1;cx.strokeStyle='#fff';cx.shadowColor='#f24';cx.shadowBlur=14;cx.lineWidth=3;cx.beginPath();p.bolt.forEach((q,i)=>i?cx.lineTo(q[0],q[1]):cx.moveTo(q[0],q[1]));cx.stroke();cx.shadowBlur=0}
else{p.x+=p.vx;p.y+=p.vy;p.vy+=p.g;p.l-=.02;cx.fillStyle=p.c;cx.beginPath();cx.arc(p.x,p.y,p.s,0,7);cx.fill()}}
cx.globalAlpha=1;requestAnimationFrame(frame)}
/* ---------- SOLVER (Prolog via /api/solve, JS fallback) ---------- */
async function solve(pos,to){try{const r=await fetch('/api/solve?pos='+pos.join(',')+'&to='+to);return(await r.json()).moves}catch(e){return solveJS(pos,to)}}
function solveJS(pos,to){const p=[...pos],o=[];(function mv(k,t){if(!k)return;const f=p[k-1];if(f==t)return mv(k-1,t);const s=P.find(x=>x!=f&&x!=t);mv(k-1,s);o.push([f,t]);p[k-1]=t;mv(k-1,t)})(p.length,to);return o}
/* ---------- BOARD ---------- */
function discBg(mi,k,n){const t=(k-1)/Math.max(1,n-1);
if(mi==0){const h=25+t*20;return`linear-gradient(180deg,hsl(${h},60%,64%),hsl(${h},55%,43%) 55%,hsl(${h},55%,30%))`}
if(mi==1){const h=t*22;return`linear-gradient(180deg,hsl(${h},85%,56%),hsl(${h},80%,37%) 55%,hsl(${h},80%,24%))`}
if(mi==2){const h=185+t*45;return`linear-gradient(180deg,hsla(${h},95%,93%,.97),hsla(${h},85%,70%,.92) 55%,hsla(${h},80%,52%,.92))`}
return'linear-gradient(180deg,#3d3649,#14101a 55%,#050308)'}
class Board{
constructor(root,mi,from,to,cb){this.r=root;this.mi=mi;this.n=MODES[mi].n;this.from=from;this.to=to;this.cb=cb||{};this.off=false;this.reset()}
reset(){this.s={a:[],b:[],c:[]};for(let k=this.n;k>=1;k--)this.s[this.from].push(k);this.sel=null;this.lock=false;this.build()}
build(){const r=this.r;r.innerHTML='';r.className='board m'+this.mi;this.H=r.clientHeight||300;this.dh=Math.min(26,(this.H-60)/this.n);this.t={};
P.forEach((p,i)=>{const t=document.createElement('div');t.className='tower';t.style.left=(i*100/3)+'%';t.innerHTML='<div class="peg" style="height:'+(this.n*this.dh+26)+'px"></div><div class="base"></div><b>'+p.toUpperCase()+'</b>';t.onclick=()=>this.click(p);r.appendChild(t);this.t[p]=t});
this.d={};for(let k=1;k<=this.n;k++){const d=document.createElement('div');d.className='disc';d.dataset.w=11+(k-1)*21/Math.max(1,this.n-1);d.style.cssText='height:'+this.dh+'px;width:'+d.dataset.w+'%;background:'+discBg(this.mi,k,this.n);r.appendChild(d);this.d[k]=d;d.style.transition='none'}
P.forEach(p=>this.s[p].forEach((k,i)=>this.put(k,p,i)))}
x(k,p){return((P.indexOf(p)+.5)*100/3-this.d[k].dataset.w/2)+'%'}
put(k,p,l){const d=this.d[k];d.style.left=this.x(k,p);d.style.bottom=(30+l*this.dh)+'px'}
pos(){const o=[];for(let k=1;k<=this.n;k++)o.push(P.find(p=>this.s[p].includes(k)));return o}
async go(f,t){const k=this.s[f].pop(),d=this.d[k],l=this.s[t].length,a=MODES[this.mi].a;this.s[t].push(k);
const hi=a.low?30+(Math.max(this.s[f].length,l)+1)*this.dh+8:this.H-this.dh-14;
d.style.zIndex=6;d.style.transition='all '+a.up+'s '+a.e;d.style.bottom=hi+'px';d.style.transform=a.f;await sleep(a.up*1000);
d.style.transition='all '+a.x+'s '+a.e;d.style.left=this.x(k,t);await sleep(a.x*1000);
d.style.transition='all '+a.up+'s '+a.e;d.style.bottom=(30+l*this.dh)+'px';d.style.transform='none';await sleep(a.up*1000);d.style.zIndex=2;
sfx(this.mi);const b=d.getBoundingClientRect();burst(b.left+b.width/2,b.top+b.height/2,this.mi);
if(this.mi==3&&!S.rm&&this.cb.shake){document.body.classList.add('shake');setTimeout(()=>document.body.classList.remove('shake'),220)}}
clearSel(){if(this.sel){const s=this.s[this.sel];if(s.length)this.d[s[s.length-1]].style.transform='none';this.t[this.sel].classList.remove('sel');this.sel=null}}
click(p){if(this.lock||this.off)return;
if(!this.sel){if(this.s[p].length){this.sel=p;this.t[p].classList.add('sel');this.d[this.s[p][this.s[p].length-1]].style.transform='translateY(-14px)'}return}
const f=this.sel;this.clearSel();if(f!==p)this.try(f,p)}
try(f,t){const a=this.s[f],b=this.s[t];if(!a.length||(b.length&&b[b.length-1]<a[a.length-1])){bad();const e=this.t[t];e.classList.add('bad');setTimeout(()=>e.classList.remove('bad'),300);return}
this.act(f,t)}
async act(f,t){this.lock=true;await this.go(f,t);this.lock=false;this.cb.move&&this.cb.move(f,t);if(this.s[this.to].length==this.n)this.cb.win&&this.cb.win()}}
/* ---------- MENU + CARD DEMOS ---------- */
let demo=null,lastPT='mouse';
function theme(i){document.body.dataset.m=i}
function buildMenu(){const c=$('#cards');c.innerHTML='';
MODES.forEach((m,i)=>{const d=document.createElement('div');d.className='card glass';d.style.setProperty('--c',m.col[0]);
d.innerHTML='<h3>'+m.name+'</h3><small>'+m.tag+'</small><div class="board"></div><div class="row"><span>'+m.n+' discs</span><button class="play">PLAY</button></div>';
c.appendChild(d);const root=d.querySelector('.board');new Board(root,i,'a','c');
d.addEventListener('pointerenter',e=>{lastPT=e.pointerType;startDemo(i,root)});d.addEventListener('pointerleave',stopDemo);
d.onclick=e=>{if(e.target.classList.contains('play')||lastPT=='mouse')openSetup(i)}})}
async function startDemo(i,root){stopDemo();theme(i);music.start(i,.4);const id={stop:false};demo=id;const b=new Board(root,i,'a','c');const mv=await solve(b.pos(),'c');
while(!id.stop){for(const[f,t]of mv){if(id.stop)return;await b.go(f,t);await sleep(100)}await sleep(900);if(id.stop)return;b.reset()}}
function stopDemo(){if(demo){demo.stop=true;demo=null}music.stop()}
/* ---------- MODAL ---------- */
function modal(h){$('#mbox').innerHTML=h;$('#modal').classList.add('on')}
function closeM(){$('#modal').classList.remove('on')}
const fmt=ms=>{const s=ms/1000;return Math.floor(s/60)+':'+(s%60).toFixed(1).padStart(4,'0')};
/* ---------- SETUP ---------- */
function openSetup(mi){stopDemo();theme(mi);const m=MODES[mi],opt=(v)=>P.map(p=>'<option value="'+p+'"'+(p==v?' selected':'')+'>Tower '+p.toUpperCase()+'</option>').join('');
modal('<h2>'+m.name+'</h2><div class="seg"><label><input type="radio" name="pm" value="1" checked> Single</label><label><input type="radio" name="pm" value="2"> Multiplayer</label></div>'+
'<div class="f" id="pcw" style="display:none">Players <select id="pcn"><option>2</option><option>3</option><option>4</option></select></div><div id="names"></div>'+
'<div class="f">Discs start on <select id="fr">'+opt('a')+'</select></div><div class="f">Move them to <select id="to">'+opt('c')+'</select></div>'+
'<div class="f">Win by <select id="wn"><option value="moves">Fewest moves</option><option value="time">Fastest time</option></select></div>'+
'<p class="err" id="err"></p><button id="go">START</button> <button class="g" id="cn">Back</button>');
const names=()=>{const multi=document.querySelector('[name=pm]:checked').value=='2',k=multi?+$('#pcn').value:1;$('#pcw').style.display=multi?'block':'none';
$('#names').innerHTML=Array.from({length:k},(_,i)=>'<div class="f">'+(multi?'Player '+(i+1)+' name':'First name')+'<input class="nm" maxlength="14"></div>').join('')};
document.querySelectorAll('[name=pm]').forEach(e=>e.onchange=names);$('#pcn').onchange=names;names();
$('#cn').onclick=()=>{closeM();theme(0)};
$('#go').onclick=()=>{const nm=[...document.querySelectorAll('.nm')].map(e=>e.value.trim()),re=/^[A-Za-z\u00C0-\u024F][A-Za-z\u00C0-\u024F .'-]{0,13}$/;
if(nm.some(x=>!re.test(x)))return $('#err').textContent='Please enter a valid first name (letters only) for every player.';
if(new Set(nm.map(x=>x.toLowerCase())).size<nm.length)return $('#err').textContent='Player names must be different.';
if($('#fr').value==$('#to').value)return $('#err').textContent='Start and target tower must be different.';
startGame({mi,players:nm,multi:nm.length>1,from:$('#fr').value,to:$('#to').value,win:$('#wn').value})}}
/* ---------- GAME ---------- */
let G={};
function startGame(o){closeM();G=Object.assign({pi:0,res:[],gen:0},o);G.n=MODES[o.mi].n;$('#menu').classList.remove('on');$('#game').classList.add('on');$('#game').classList.toggle('multi',G.multi);
$('#mname').textContent=MODES[o.mi].name+'  '+o.from.toUpperCase()+' \u2192 '+o.to.toUpperCase();newTurn()}
function newTurn(){G.gen++;clearInterval(G.iv);G.run=false;G.moves=0;G.undo=[];G.acc=0;G.auto=false;theme(G.mi||G.mi===0?G.mi:0);theme(G.mi);music.start(G.mi,.5);
G.b=new Board($('#gb'),G.mi,G.from,G.to,{shake:1,move:(f,t)=>{G.moves++;G.undo.push([f,t]);hud()},win:()=>finish()});
$('#pname').textContent=G.players[G.pi];hud();toast('');
if(G.multi){G.b.off=true;modal('<h2>ARE YOU READY?</h2><p style="font-size:22px">'+G.players[G.pi]+'</p><p>Timer starts when you press the button.</p><button id="rd">I\'M READY - START</button>');$('#rd').onclick=()=>{closeM();begin()}}else begin()}
function begin(){G.b.off=false;G.t0=performance.now();G.run=true;clearInterval(G.iv);G.iv=setInterval(hud,200);hud()}
function stopT(){if(G.run){G.acc+=performance.now()-G.t0;G.run=false}clearInterval(G.iv)}
const el=()=>G.acc+(G.run?performance.now()-G.t0:0);
function hud(){$('#mv').textContent=G.moves+' / '+((1<<G.n)-1);$('#tm').textContent=fmt(el());document.querySelectorAll('.ht').forEach(e=>e.style.display=S.timer?'':'none')}
function toast(t){$('#toast').textContent=t}
const lbk=()=>'hl'+G.mi+G.win,MEM={};
const lbGet=()=>{try{return JSON.parse(localStorage.getItem(lbk())||'[]')}catch(e){return MEM[lbk()]||[]}};
const cmp=(a,b)=>G.win=='moves'?a.m-b.m||a.t-b.t:a.t-b.t||a.m-b.m;
function lbAdd(e){const l=lbGet();l.push(e);l.sort(cmp);const t=l.slice(0,5);try{localStorage.setItem(lbk(),JSON.stringify(t))}catch(x){MEM[lbk()]=t}return t}
function table(rows,rank){return'<table><tr><th>'+(rank?'#':'')+'</th><th>Name</th><th>Moves</th><th>Time</th></tr>'+rows.map((r,i)=>'<tr><td>'+(rank?i+1:'')+'</td><td>'+r.n+'</td><td>'+r.m+'</td><td>'+fmt(r.t)+'</td></tr>').join('')+'</table>'}
function party(){winSnd();for(let i=0;i<10;i++)setTimeout(()=>burst(Math.random()*innerWidth,Math.random()*innerHeight*.6,0),i*120)}
function finish(){stopT();G.b.off=true;const e={n:G.players[G.pi],m:G.moves,t:G.acc};party();
if(!G.multi){const top=lbAdd(e);modal('<h2>Congratulations, '+e.n+'!</h2><p>You solved '+MODES[G.mi].name+' in <b>'+e.m+'</b> moves and <b>'+fmt(e.t)+'</b>.</p><p>Optimal: '+((1<<G.n)-1)+' moves</p><h3>Leaderboard ('+(G.win=='moves'?'fewest moves':'fastest time')+')</h3>'+table(top,1)+'<button id="pa">Play again</button> <button class="g" id="mn">Menu</button>');
$('#pa').onclick=()=>{closeM();newTurn()};$('#mn').onclick=toMenu;return}
G.res.push(e);
if(G.pi<G.players.length-1){modal('<h2>'+e.n+' finished!</h2><p>'+e.m+' moves &middot; '+fmt(e.t)+'</p><p>Next up: <b>'+G.players[G.pi+1]+'</b></p><button id="nx">Next player</button>');$('#nx').onclick=()=>{closeM();G.pi++;newTurn()}}
else{const r=[...G.res].sort(cmp);modal('<h2>Final Results</h2><p>Winner: <b>'+r[0].n+'</b> (by '+(G.win=='moves'?'fewest moves':'fastest time')+')</p>'+table(r,1)+'<button id="mn">Menu</button>');$('#mn').onclick=toMenu}}
function toMenu(){closeM();stopT();G.gen++;music.stop();$('#game').classList.remove('on');$('#menu').classList.add('on');theme(0);buildMenu()}
async function autoPlay(){if(G.auto||G.b.lock)return;stopT();G.auto=true;G.b.off=true;G.b.clearSel();const g=G.gen;toast('Auto-solving (Prolog)...');
const mv=await solve(G.b.pos(),G.to);for(const[f,t]of mv){if(g!=G.gen)return;await G.b.go(f,t);await sleep(120)}
if(g!=G.gen)return;toast('');modal('<h2>Auto-solve complete</h2><p>Try it yourself!</p><p style="opacity:.8">No score is saved for auto play.</p><button id="rs">Try it myself</button> <button class="g" id="mn">Menu</button>');$('#rs').onclick=()=>{closeM();newTurn()};$('#mn').onclick=toMenu}
$('#brs').onclick=()=>newTurn();
$('#bun').onclick=async()=>{const b=G.b;if(!G.undo.length||b.lock||b.off||G.auto)return;b.clearSel();const[f,t]=G.undo.pop();b.lock=true;await b.go(t,f);b.lock=false;G.moves--;hud()};
$('#bhi').onclick=async()=>{if(G.b.lock||G.b.off||G.auto)return;const mv=await solve(G.b.pos(),G.to);if(!mv.length)return;const[f,t]=mv[0];toast('Hint: move top disc '+f.toUpperCase()+' \u2192 '+t.toUpperCase());[f,t].forEach(p=>G.b.t[p].classList.add('hint'));setTimeout(()=>{[f,t].forEach(p=>G.b.t[p].classList.remove('hint'));toast('')},2000)};
$('#bau').onclick=autoPlay;
$('#bpa').onclick=()=>{if(G.auto)return;stopT();G.b.off=true;modal('<h2>Paused</h2><button id="rm">Resume</button>');$('#rm').onclick=()=>{closeM();G.b.off=false;G.t0=performance.now();G.run=true;G.iv=setInterval(hud,200)}};
$('#bq').onclick=()=>{if(confirm('Leave this game? Progress will be lost.'))toMenu()};
/* ---------- SETTINGS ---------- */
function openSettings(){modal('<h2>Settings</h2><div class="f">Music volume<input type="range" id="sm" min="0" max="1" step=".05" value="'+S.music+'"></div><div class="f">SFX volume<input type="range" id="sf" min="0" max="1" step=".05" value="'+S.sfx+'"></div>'+
'<div class="f"><label><input type="checkbox" id="mu" style="width:auto"'+(S.mute?' checked':'')+'> Mute all</label></div><div class="f">Petal density<select id="sp"><option value="0">Off</option><option value="1">Low</option><option value="2">Medium</option><option value="3">High</option></select></div>'+
'<div class="f"><label><input type="checkbox" id="rm2" style="width:auto"'+(S.rm?' checked':'')+'> Reduce motion</label></div><div class="f"><label><input type="checkbox" id="st" style="width:auto"'+(S.timer?' checked':'')+'> Show timer &amp; move counter</label></div><button id="ok">Done</button>');
$('#sp').value=S.petals;
$('#sm').oninput=e=>{S.music=+e.target.value;vol();saveS()};$('#sf').oninput=e=>{S.sfx=+e.target.value;vol();saveS()};$('#mu').onchange=e=>{S.mute=e.target.checked;vol();saveS()};
$('#sp').onchange=e=>{S.petals=+e.target.value;initPetals();saveS()};$('#rm2').onchange=e=>{S.rm=e.target.checked;saveS()};$('#st').onchange=e=>{S.timer=e.target.checked;hud();saveS()};$('#ok').onclick=closeM}
$('#bset').onclick=openSettings;$('#bset2').onclick=openSettings;
$('#gate').onclick=()=>{initAudio();$('#gate').style.display='none';$('#menu').classList.add('on');buildMenu()};
initPetals();frame();
</script></body></html>
HTML-END*/
