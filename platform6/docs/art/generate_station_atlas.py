"""Rebuild the original, deterministic station surface sheet (no downloaded assets)."""
from pathlib import Path
parts=['<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="512" viewBox="0 0 1024 512">']
def rect(x,y,w,h,c,extra=''):parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" {extra}/>')
def path(d,c,w=2):parts.append(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>')
for i in range(8):
 x=(i%4)*256;y=(i//4)*256
 parts.append(f'<g transform="translate({x} {y})">')
 rect(0,0,256,256,['#ece7df','#e5d3b6','#e5e0d7','#f0e8d4','#b7c7dc','#788ba9','#e6d6ae','#dac8ad'][i])
 if i==0:
  # Broad stone scumbles and corner wear, no per-pixel noise.
  for xx,yy,ww,hh in [(18,24,67,5),(148,83,70,9),(49,201,107,6),(29,106,34,3),(175,216,54,4)]:rect(xx,yy,ww,hh,'#d4cfc7','rx="3"')
  path('M 22 222 Q 61 210 92 221','#b7b6b9',3);path('M 5 10 L 5 80 M 10 5 L 88 5','#c2bfc0',3)
 elif i==1:
  for yy in [17,38,62,92,121,157,186,220,245]:path(f'M 0 {yy} Q 70 {yy-8} 140 {yy+3} T 256 {yy-4}','#ac9174',2)
  parts.append('<ellipse cx="170" cy="96" rx="27" ry="6" fill="none" stroke="#b79d7d" stroke-width="3"/>')
  path('M 0 9 L 256 9 M 0 249 L 256 249','#f8e8c4',4)
 elif i==2:
  for xx,yy,ww,hh in [(11,28,83,19),(150,80,77,10),(33,180,131,13),(181,227,63,17)]:rect(xx,yy,ww,hh,'#cfcbd0','rx="5"')
  path('M 32 68 L 47 90 L 41 129','#bbb7c3',2)
 elif i==3:
  path('M 12 0 L 12 256 M 244 0 L 244 256','#aaa9ad',3)
  path('M 17 20 L 239 20 M 17 236 L 239 236','#d8cfb9',3)
  for xx in [28,228]:
   for yy in [31,128,225]:parts.append(f'<circle cx="{xx}" cy="{yy}" r="3" fill="#a8a6ac"/>')
  path('M 58 209 Q 116 202 174 214','#cfc3a9',3)
 elif i==4:
  path('M 0 6 L 256 6 M 0 250 L 256 250 M 7 0 L 7 256 M 249 0 L 249 256','#71839d',5)
  path('M 42 29 L 76 29 M 25 46 L 62 46 M 178 215 L 229 215','#d9dfde',4)
  parts.append('<path d="M 14 237 L 239 14 L 246 46 L 45 242 Z" fill="#cbd4e0" opacity=".25"/>')
 elif i==5:
  rect(0,0,256,256,'#7485a1');rect(20,0,9,256,'#687996');rect(229,0,9,256,'#687996')
  for xx in [59,113,167]:
   for yy in [36,96,156,216]:
    rect(xx,yy,24,30,'#9fa0ac');rect(xx+3,yy+3,18,24,'#cfba97' if (xx+yy)%3 else '#8997ae');rect(xx+11,yy,3,30,'#7a859a')
 elif i in [6,7]:
  rect(12,12,232,232,'#f5e7c8');rect(25,25,206,155,'#819eb2' if i==6 else '#929fad')
  if i==6:
   parts.append('<circle cx="172" cy="64" r="23" fill="#f2d795"/><path d="M 25 123 Q 100 109 161 126 T 231 118 L 231 180 L 25 180 Z" fill="#4d748e"/><path d="M 25 155 Q 93 141 153 158 T 231 152" fill="none" stroke="#bccac4" stroke-width="5"/>')
  else:
   parts.append('<path d="M 25 180 L 83 65 L 132 125 L 178 82 L 231 180 Z" fill="#667481"/><path d="M 61 108 L 83 65 L 107 95 L 88 89 Z" fill="#e3dcca"/>')
  rect(41,202,174,8,'#718091');rect(74,219,108,4,'#a39480')
 parts.append('</g>')
parts.append('</svg>')
Path('game/art/station/surface_atlas.svg').write_text('\n'.join(parts)+'\n')
