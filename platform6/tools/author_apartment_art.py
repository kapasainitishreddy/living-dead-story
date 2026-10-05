"""Original deterministic SVG brush textures for the shared apartment. No external assets."""
from pathlib import Path
import random
ROOT=Path(__file__).resolve().parents[1]/'game/art/apartment'
ROOT.mkdir(parents=True,exist_ok=True)
r=random.Random(317)
def save(name,w,h,body):
    (ROOT/(name+'.svg')).write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'+body+'</svg>')
for name,base,inks in [('plaster','#e1d5c1',['#cec2b3','#eee2cc','#d3c8b9']),('cloth','#e6ddc6',['#d1c4ac','#f0e8d1','#e0d1b8']),('wood','#ab8060',['#88684f','#c69872','#a37959'])]:
    s=f'<rect width="512" height="512" fill="{base}"/>'
    for i in range(190):
        x,y=r.randrange(512),r.randrange(512)
        length=r.randrange(16,90) if name!='wood' else r.randrange(80,260)
        s+=f'<path d="M{x},{y} q{length//2},{r.randrange(-5,6)} {length},{r.randrange(-8,9)}" fill="none" stroke="{r.choice(inks)}" stroke-width="{r.randrange(1,6)}" opacity="{r.uniform(.18,.38):.2f}"/>'
    if name=='cloth':
        for i in range(0,512,8): s+=f'<path d="M0,{i} H512 M{i},0 V512" stroke="#a9957d" stroke-width=".4" opacity=".14"/>'
    save(name,512,512,s)
# Painted matte is viewed behind physical frame and curtains. A city that is awake in a few windows.
s='''<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#293951"/><stop offset=".66" stop-color="#596a82"/><stop offset="1" stop-color="#a49384"/></linearGradient><linearGradient id="haze" x2="0" y2="1"><stop stop-color="#718a9e" stop-opacity="0"/><stop offset="1" stop-color="#889cad" stop-opacity=".4"/></linearGradient></defs><rect width="1024" height="512" fill="url(#sky)"/>'''
for layer,col,ybase in [(0,'#5d7087',370),(1,'#43546d',435),(2,'#2c3d55',512)]:
    x=-20
    while x<1024:
        w=r.randrange(45,120); h=r.randrange(70,230)
        y=ybase-h
        s+=f'<path d="M{x},{ybase} V{y} l{w//2},-{r.randrange(0,14)} L{x+w},{y} V{ybase}Z" fill="{col}"/>'
        s+=f'<path d="M{x+7},{y+8} H{x+w-9}" stroke="#8c8b91" stroke-width="3" opacity=".28"/>'
        for xx in range(x+12,x+w-10,19):
            for yy in range(y+22,ybase-12,26):
                if r.random()<.22:
                    s+=f'<rect x="{xx}" y="{yy}" width="7" height="10" rx="1" fill="{r.choice(["#c6ab86","#e8c58b","#839caf"])}" opacity="{r.uniform(.45,.8):.2f}"/>'
        x+=w+r.randrange(5,15)
s+='<rect width="1024" height="512" fill="url(#haze)"/>'
for i in range(85):
    x,y=r.randrange(1024),r.randrange(512)
    s+=f'<path d="M{x},{y} l-4,24" stroke="#c4d4df" stroke-width="1" opacity=".11"/>'
for i in range(100):
    x,y=r.randrange(1024),r.randrange(512)
    s+=f'<path d="M{x},{y} q-2,8 0,13" stroke="#d9e4e8" stroke-width="2" opacity=".16"/>'
s+='<path d="M0,495 Q300,485 1024,500" fill="none" stroke="#d7dee0" stroke-width="17" opacity=".17"/>'
save('city_window',1024,512,s)
print('Authored 4 original editable SVG apartment textures')
