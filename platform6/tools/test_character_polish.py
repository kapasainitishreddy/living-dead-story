"""Exported mesh regressions for coherent tailored cloth and rounded face."""
from test_authored_character_assets import load, accessor, DEST, check_character

def check(slug):
 g,b,_=load(DEST/slug/(slug+'.glb'))
 nodes={n['name']:n for n in g['nodes'] if 'mesh' in n}
 def data(name,field):return accessor(g,b,g['meshes'][nodes[name]['mesh']]['primitives'][0]['attributes'][field])
 # A face contour must interpolate between old eight stations instead of flat cheek bands.
 assert len(data('SculptedFace','POSITION'))>1500,'Face contour is still eight coarse rings'
 assert len(data('FaceEyeLeft','POSITION'))>40,'Eye silhouette remains an angular eight-point patch'
 # Round nose is a continuous modeled surface rather than six wedge faces.
 assert len(data('Nose','POSITION'))>200,'Nose remains a hard six-face wedge'
 if slug=='mira':
  joint_names=[g['nodes'][i]['name'] for i in g['skins'][0]['joints']]
  for panel in ['CoatFrontLeft','CoatFrontRight']:
   pos=data(panel,'POSITION');weights=data(panel,'WEIGHTS_0');joints=data(panel,'JOINTS_0')
   for p,ww,jj in zip(pos,weights,joints):
    if p[1]<.86:
     by_name={joint_names[j]:w for j,w in zip(jj,ww)}
     assert by_name.get('Hips',0)>.5,'Coat hem separates under pelvis motion'
 check_character(slug)
for slug in ['protagonist','mira']:check(slug)
print('CHARACTER_POLISH_EXPORTED_CONTRACT passed')
