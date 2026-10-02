// WORLD CANVAS
const c=document.getElementById('world'),ctx=c.getContext('2d'); let W,H,DPR;
const sceneMood={value:.05,target:.05}; let t=0, flash=0;
const rain=Array.from({length:130},()=>({x:Math.random(),y:Math.random(),l:.015+Math.random()*.04,s:.003+Math.random()*.007}));
const buildings=Array.from({length:34},(_,i)=>({x:i/33,w:.02+Math.random()*.026,h:.14+Math.random()*.34,seed:Math.random()*10}));
function resize(){DPR=Math.min(devicePixelRatio||1,2);W=innerWidth;H=innerHeight;c.width=W*DPR;c.height=H*DPR;c.style.width=W+'px';c.style.height=H+'px';ctx.setTransform(DPR,0,0,DPR,0,0);resizeStars()}
addEventListener('resize',resize);

function skyline(){
  const m=sceneMood.value;
  let g=ctx.createLinearGradient(0,0,0,H);g.addColorStop(0,`rgb(${8+30*m},${10+35*m},${20+58*m})`);g.addColorStop(.62,`rgb(${11+18*m},${14+23*m},${24+38*m})`);g.addColorStop(1,'#05070c');ctx.fillStyle=g;ctx.fillRect(0,0,W,H);
  // moon halo
  let rg=ctx.createRadialGradient(W*.78,H*.18,0,W*.78,H*.18,H*.28);rg.addColorStop(0,`rgba(190,210,255,${.10+.18*m})`);rg.addColorStop(1,'rgba(0,0,0,0)');ctx.fillStyle=rg;ctx.fillRect(0,0,W,H*.6);
  // far haze
  ctx.fillStyle=`rgba(100,120,150,${.03+.06*m})`;ctx.fillRect(0,H*.47,W,H*.25);
  buildings.forEach((b,i)=>{
    const x=b.x*W-W*.02,w=b.w*W,h=b.h*H,y=H*.74-h;
    ctx.fillStyle=`rgba(${8+10*m},${11+13*m},${18+18*m},.98)`;ctx.fillRect(x,y,w,h);
    const cols=Math.max(2,Math.floor(w/16)),rows=Math.max(3,Math.floor(h/19));
    for(let cy=0;cy<rows;cy++) for(let cx=0;cx<cols;cx++){
      const p=(Math.sin((i+1)*17.3+cx*3.1+cy*5.7)+1)/2;
      if(p < .12+m*.34){
        const alpha=.05+m*.62;
        ctx.fillStyle=`rgba(255,210,128,${alpha})`;
        ctx.fillRect(x+5+cx*13,y+8+cy*17,5,7);
      }
    }
  });
  // foreground street
  ctx.fillStyle='rgba(3,5,9,.96)';ctx.fillRect(0,H*.74,W,H*.26);
  // road reflection
  let r=ctx.createLinearGradient(W*.52,H*.74,W*.52,H);r.addColorStop(0,`rgba(255,194,105,${.02+.12*m})`);r.addColorStop(1,'rgba(255,194,105,0)');ctx.fillStyle=r;ctx.beginPath();ctx.moveTo(W*.47,H*.74);ctx.lineTo(W*.57,H*.74);ctx.lineTo(W*.75,H);ctx.lineTo(W*.28,H);ctx.closePath();ctx.fill();
  // one signal window
  const px=W*.22,py=H*.34;
  let glow=ctx.createRadialGradient(px,py,0,px,py,60+20*Math.sin(t*.003));glow.addColorStop(0,`rgba(255,216,142,${.55+.2*Math.sin(t*.004)})`);glow.addColorStop(1,'rgba(255,190,90,0)');ctx.fillStyle=glow;ctx.fillRect(px-100,py-100,200,200);ctx.fillStyle='#ffd896';ctx.fillRect(px-5,py-4,10,8);
  // rain
  ctx.strokeStyle=`rgba(180,205,235,${.11-.04*m})`;ctx.lineWidth=1;
  rain.forEach(rn=>{rn.y+=rn.s;if(rn.y>1){rn.y=0;rn.x=Math.random()}ctx.beginPath();ctx.moveTo(rn.x*W,rn.y*H);ctx.lineTo(rn.x*W-5,rn.y*H+rn.l*H);ctx.stroke()});
  // fog ribbons
  for(let i=0;i<3;i++){const yy=H*(.56+i*.08)+Math.sin(t*.0003+i)*16;let fg=ctx.createLinearGradient(0,yy,W,yy);fg.addColorStop(0,'rgba(190,205,230,0)');fg.addColorStop(.5,`rgba(190,205,230,${.025+.02*Math.sin(t*.0005+i)})`);fg.addColorStop(1,'rgba(190,205,230,0)');ctx.fillStyle=fg;ctx.fillRect(0,yy,W,28)}
  if(flash>0){ctx.fillStyle=`rgba(255,224,170,${flash})`;ctx.fillRect(0,0,W,H);flash*=.93}
}
function loop(ms){t=ms;sceneMood.value+=(sceneMood.target-sceneMood.value)*.018;ctx.clearRect(0,0,W,H);skyline();requestAnimationFrame(loop)}
function burst(){flash=.18;showToast("The city remembers.");}

// constellation
const sc=document.getElementById('constellation'),sctx=sc.getContext('2d'); let SW,SH;
function resizeStars(){const r=sc.getBoundingClientRect();SW=r.width;SH=r.height;sc.width=SW*DPR;sc.height=SH*DPR;sctx.setTransform(DPR,0,0,DPR,0,0);drawStars()}
function drawStars(){
  sctx.clearRect(0,0,SW,SH);
  const n=Math.max(3,state.threads.length+3), pts=[];
  for(let i=0;i<n;i++){const a=i*2.399,rad=(18+(i*7)%Math.max(22,SW*.36));pts.push([SW/2+Math.cos(a)*rad,SH/2+Math.sin(a)*rad])}
  sctx.strokeStyle='rgba(180,205,255,.14)';sctx.lineWidth=1;sctx.beginPath();pts.forEach((p,i)=>i?sctx.lineTo(...p):sctx.moveTo(...p));sctx.stroke();
  pts.forEach((p,i)=>{sctx.beginPath();sctx.fillStyle=i<state.threads.length?'rgba(255,221,155,.95)':'rgba(180,200,235,.22)';sctx.arc(p[0],p[1],i<state.threads.length?2.4:1.2,0,Math.PI*2);sctx.fill()})
}
setInterval(drawStars,1200);
resize();requestAnimationFrame(loop);start();
