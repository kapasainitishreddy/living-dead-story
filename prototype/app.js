const panel = document.getElementById('panel');
const toast = document.getElementById('toast');
const chip = document.getElementById('lightsChip');
const state = JSON.parse(localStorage.getItem('stillHereState') || '{"lights":0,"threads":[],"visited":0}');
state.visited += 1; save();
function save(){ localStorage.setItem('stillHereState', JSON.stringify(state)); chip.textContent=`${state.lights} light${state.lights===1?'':'s'} found`; }

function showToast(t){toast.textContent=t;toast.classList.add('show');setTimeout(()=>toast.classList.remove('show'),2200)}
function setPanel(html){panel.innerHTML=html; panel.scrollTop=0;}
function actions(items){
  return `<div class="actions">${items.map((x,i)=>`<button class="action ${x.primary?'primary':''}" data-i="${i}"><strong>${x.title}</strong><span>${x.sub||''}</span></button>`).join('')}</div>`;
}
function bind(items){panel.querySelectorAll('[data-i]').forEach(b=>b.onclick=()=>items[+b.dataset.i].go())}

function start(){
  sceneMood.target=.05;
  setPanel(`
    <div class="eyebrow">The Quiet City · 03:17</div>
    <h1>Everyone is awake.<br/>Nobody is living.</h1>
    <p>The trains still run. The stores still open. People still answer when spoken to. But three weeks ago the city stopped wanting anything.</p>
    <p class="quote">Tonight, one window turns on.</p>
    ${actions([{title:"Find the light",sub:"Begin a 5–8 minute story journey.",primary:true,go:pulse},{title:"I only have a minute",sub:"Start a tiny Night Run.",go:nightRun}])}
    <div class="safe">This prototype is a narrative wellbeing game, not crisis care. If you may hurt yourself or are in immediate danger, use the <a href="#" id="helpNow">help-now screen</a>.</div>
  `);
  bind([{go:pulse},{go:nightRun}]); bindHelp();
}
function bindHelp(){const a=document.getElementById('helpNow'); if(a)a.onclick=(e)=>{e.preventDefault();helpNow();}}
function pulse(){
  const opts=[
    {title:"I can barely carry anything",sub:"2-minute path. No pressure.",go:()=>signal('tiny')},
    {title:"I can do something small",sub:"5-minute path.",go:()=>signal('small')},
    {title:"I want to explore",sub:"Full scene and puzzle.",go:()=>signal('full')},
    {title:"Just stay with me",sub:"No objectives. Enter a quiet room.",go:sanctuary},
  ];
  setPanel(`<div class="eyebrow">Before we go</div><h2>What can you carry tonight?</h2><p>No score. No diagnosis. This only changes how much the game asks of you.</p>${actions(opts)}`);
  bind(opts);
}
function signal(mode){
  sceneMood.target=.18;
  const opts=[
    {title:"Follow the radio signal",sub:"The impossible platform is beneath Central Station.",primary:true,go:()=>station(mode)},
    {title:"Inspect the photograph",sub:"Someone in it has been erased.",go:()=>photo(mode)}
  ];
  setPanel(`<div class="eyebrow">Signal 001</div><h2>“PLATFORM 6 DOES NOT EXIST.”</h2>
  <p>Your dead radio clicks on by itself. A voice whispers the same sentence three times.</p>
  <p class="quote">“Do not board the 3:17 train.”</p>
  <p>On the table beside it is a photograph you don't remember taking.</p>${actions(opts)}`);
  bind(opts);
}
function station(mode){
  sceneMood.target=.28;
  const opts=[
    {title:"Touch the warm ticket",sub:"It has today's date and your handwriting.",go:()=>realAction(mode,'curiosity')},
    {title:"Ask the silent conductor",sub:"He points at the dark tunnel.",go:()=>realAction(mode,'connection')},
    {title:"Leave",sub:"Nothing is lost. You can return later.",go:start}
  ];
  setPanel(`<div class="eyebrow">Central Station · Platform 6</div><h2>The train has no destination.</h2>
  <p>Every departure board reads <b>UNKNOWN</b>. Inside the empty carriage, one paper ticket is glowing faintly.</p>
  <p class="quote">Somewhere in the tunnel, something knocks back.</p>${actions(opts)}`);
  bind(opts);
}
function photo(mode){
  const opts=[
    {title:"Turn the photograph over",sub:"A message is written behind it.",go:()=>realAction(mode,'memory')},
    {title:"Put it away",sub:"You don't have to open every door tonight.",go:start}
  ];
  setPanel(`<div class="eyebrow">Evidence</div><h2>Someone is missing from the picture.</h2>
  <p>Four people are standing around a birthday cake. There are five plates.</p>
  <p>Where the fifth person should be, the image isn't torn. It is simply unfinished.</p>${actions(opts)}`);
  bind(opts);
}
function realAction(mode, thread){
  let options = mode==='tiny' ? [
    ["Take one slow breath","No timer. Just notice the exhale."],
    ["Put both feet on the floor","That is enough movement."],
    ["Skip this","The story still continues."]
  ] : mode==='small' ? [
    ["Drink some water","One glass, or even one sip."],
    ["Open a curtain or step to a window","Look outside for ten seconds."],
    ["Stand and stretch","No workout. Just change position."],
    ["Skip this","The story still continues."]
  ] : [
    ["Walk to another room and back","About one minute."],
    ["Send someone a low-pressure message","Even a meme counts."],
    ["Get water or make something warm","Tea, coffee, anything."],
    ["Step outside or to a window","Notice one thing you didn't see before."],
    ["Skip this","No punishment."]
  ];
  const acts=options.map((o,idx)=>({title:o[0],sub:o[1],primary:idx===0,go:()=>powerTrain(thread, idx===options.length-1)}));
  setPanel(`<div class="eyebrow">The train needs power</div><h2>Move something in your world.</h2>
    <p>This is not proof-of-completion. The game trusts you.</p>
    <p class="quote">A tiny action here can move something enormous there.</p>${actions(acts)}`);
  bind(acts);
}
function powerTrain(thread, skipped){
  if(!skipped){
    state.lights += 1;
    state.threads.push({type:thread, at:Date.now()});
    save();
    sceneMood.target=Math.min(.78,.24+state.lights*.13);
    burst();
  }
  const label = skipped ? "The conductor starts an emergency generator." : "WHUM. One carriage ignites with amber light. Then the next. Then the next.";
  const learned = thread==='curiosity' ? "You boarded because you wanted to know." : thread==='connection' ? "You followed another person's signal." : "You noticed what was missing.";
  setPanel(`<div class="eyebrow">Journey complete</div><h2>The train moves.</h2>
    <p>${label}</p>
    <div id="threadCard"><div class="orb"></div><div><b>${skipped?'NO THREAD REQUIRED':'THREAD FOUND'}</b><div class="small">${skipped?'You can continue without earning anything.':learned}</div></div></div>
    <p class="quote">“The dead aren't losing their reasons,” the conductor says. “Someone is taking them.”</p>
    ${actions([{title:"Continue another night",sub:"Your city remembers this journey.",primary:true,go:start},{title:"Visit the Sanctuary",sub:"See what the city remembers about you.",go:sanctuary}])}`);
  bind([{go:start},{go:sanctuary}]);
}
function nightRun(){
  const opts=[
    {title:"Find one warm thing",sub:"Blanket, drink, shower, sunlight. Anything.",go:()=>powerTrain('care',false)},
    {title:"Look at one far-away thing",sub:"A cloud, building, tree, star, anything.",go:()=>powerTrain('wonder',false)},
    {title:"Skip the action",sub:"Sit in the scene for a moment instead.",go:()=>powerTrain('rest',true)}
  ];
  setPanel(`<div class="eyebrow">Night Run · 90 seconds</div><h2>One signal is still blinking.</h2><p>You do not need to fix the city tonight.</p><p class="quote">Find one small thing that tells your body the night is still moving.</p>${actions(opts)}`);
  bind(opts);
}
function sanctuary(){
  const counts={}; state.threads.forEach(t=>counts[t.type]=(counts[t.type]||0)+1);
  const list=Object.entries(counts).map(([k,v])=>`<div class="threadRow"><b>${k.toUpperCase()}</b> · ${v}</div>`).join('') || '<span class="small">No threads yet. That is okay.</span>';
  setPanel(`<div class="eyebrow">Sanctuary</div><h2>Nothing here expires.</h2>
    <p>Your world does not punish absence. Come back tomorrow, next month, or next year.</p>
    <div id="threadCard"><div class="orb"></div><div><b>${state.lights} LIGHT${state.lights===1?'':'S'} FOUND</b><div class="small">${list}</div></div></div>
    <p class="quote">“You do not have to rebuild everything tonight.”</p>
    ${actions([{title:"Return to the city",sub:"Continue when you want.",primary:true,go:start},{title:"I need immediate help",sub:"Leave the fiction and show support options.",go:helpNow}])}`);
  bind([{go:start},{go:helpNow}]);
}
function helpNow(){
  setPanel(`<div class="eyebrow">Help now</div><h2>Leave the game for a moment.</h2>
    <p>If you might act on thoughts of harming yourself, contact emergency services or a crisis service now, and if possible move toward another person or a safer place.</p>
    <div class="actions">
      <a class="action primary" style="display:block;text-decoration:none" href="tel:988"><strong>Call 988 (U.S.)</strong><span>Suicide & Crisis Lifeline</span></a>
      <a class="action" style="display:block;text-decoration:none" href="sms:988"><strong>Text 988 (U.S.)</strong><span>Connect with a crisis counselor</span></a>
      <a class="action" style="display:block;text-decoration:none" href="tel:911"><strong>Call 911</strong><span>If there is immediate danger</span></a>
    </div>
    <p class="small" style="margin-top:16px">For a production release, this screen should localize resources by country and let the user pre-save trusted contacts and a personal safety plan.</p>
    ${actions([{title:"Return to Sanctuary",sub:"No score or progress is attached to this screen.",go:sanctuary}])}`);
  bind([{go:sanctuary}]);
}

document.getElementById('resetBtn').onclick=()=>{localStorage.removeItem('stillHereState'); location.reload()};
document.getElementById('sanctuaryBtn').onclick=sanctuary;
