#!/usr/bin/env python3
"""Author the original panoramic painted twilight; no borrowed assets or downloads."""
from pathlib import Path
import random
ROOT=Path(__file__).resolve().parents[1]/'game/art/opening_depth'
ROOT.mkdir(parents=True,exist_ok=True)
rng=random.Random(3176)
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="2048" height="1024" viewBox="0 0 2048 1024">',
'''<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#192c47"/><stop offset=".35" stop-color="#3c5272"/><stop offset=".47" stop-color="#7c8193"/><stop offset=".515" stop-color="#bca09f"/><stop offset=".555" stop-color="#7e8d9f"/><stop offset=".69" stop-color="#526d80"/><stop offset="1" stop-color="#344654"/></linearGradient><linearGradient id="cloud" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#67728c" stop-opacity="0"/><stop offset=".6" stop-color="#8d92a8" stop-opacity=".48"/><stop offset="1" stop-color="#c0aba8" stop-opacity=".13"/></linearGradient></defs><rect width="2048" height="1024" fill="url(#sky)"/>''']
# Sparse curved cloud brush shapes, including curved returns at both ends.
# The full contours avoid the straight closing diagonals of sky-wide ribbons.
for row,(base_y,base_width,base_height) in enumerate([(355,300,40),(424,330,28),(479,240,17)]):
    for i in range(6):
        x=-170+i*365+(row%2)*145+rng.randrange(-25,25)
        y=base_y+rng.randrange(-10,11)
        w=base_width+rng.randrange(-55,65); h=base_height+rng.randrange(-4,5)
        coords=[(.07,-.15,.12,-.10,.16,-.10),(.25,-.75,.35,-.95,.42,-.50),(.50,-.85,.62,-.75,.69,-.30),(.78,-.35,.88,-.16,1.0,0),(.77,.04,.51,.11,.34,.10),(.21,.12,.04,.08,0,0)]
        curve=' '.join('C'+','.join(f'{x+v*w:.1f}' if j%2==0 else f'{y+v*h:.1f}' for j,v in enumerate(segment)) for segment in coords)
        path=f'M{x},{y} {curve} Z'
        parts.append(f'<path d="{path}" fill="url(#cloud)" opacity="{.34+row*.045:.2f}"/>')
# Sparse tiny stars remain subordinate to the real lighthouse, arch and constellation.
for _ in range(37):
    x=rng.randrange(0,2048); y=rng.randrange(130,385)
    parts.append(f'<circle cx="{x}" cy="{y}" r="{rng.choice([.6,.8,1.0])}" fill="#d8d7d4" opacity="{rng.uniform(.18,.39):.2f}"/>')
# Low-contrast horizontal dry-brush bands make the wash feel painted, not a flat game clear.
for _ in range(54):
    x=rng.randrange(-100,2048); y=rng.randrange(320,550); w=rng.randrange(50,220)
    parts.append(f'<path d="M{x},{y} q{w/2:.1f},{rng.randrange(-3,4)} {w},0" fill="none" stroke="#b3acb4" stroke-width="{rng.choice([1,2,3])}" opacity=".035"/>')
parts.append('</svg>')
(ROOT/'twilight_panorama.svg').write_text('\n'.join(parts))
print(ROOT/'twilight_panorama.svg')
