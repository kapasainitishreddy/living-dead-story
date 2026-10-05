"""Real exported-mesh regressions for the approved hero warmth pass."""
from test_authored_character_assets import load, accessor, DEST
for slug in ['protagonist','mira']:
 g,b,_=load(DEST/slug/(slug+'.glb'))
 nodes={n['name']:n for n in g['nodes'] if 'mesh' in n}
 def positions(name):return accessor(g,b,g['meshes'][nodes[name]['mesh']]['primitives'][0]['attributes']['POSITION'])
 lid=positions('FaceLidLeft');eye=positions('FaceEyeLeft')
 assert len(lid)>=30,'Upper eyelid remains a coarse unmatched five-station strip'
 assert max(p[1] for p in lid)>=max(p[1] for p in eye)-.003,'Upper eyelid cuts inside the eye white'
 # Every exported rim vertex must follow the actual white boundary, not only its apex.
 boundary=eye[1:]
 assert all(min(((p[0]-q[0])**2+(p[1]-q[1])**2)**.5 for q in boundary)<.004 for p in lid),'Eyelid contour separates from its almond eye boundary'
 jaw=[p for p in positions('SculptedFace') if 1.392<p[1]<1.4]
 assert max(abs(p[0]) for p in jaw)<.108,'Lower face loses deliberate cheek-to-chin taper'
 iris=positions('FaceIrisLeft')
 assert max(p[0] for p in iris)-min(p[0] for p in iris)>.033,'Iris does not fill the calmer almond silhouette'
 assert 'HairFringeAccent' in nodes,'Broad original fringe lacks directional accent'
 if slug=='mira':
  assert abs(min(p[1] for p in positions('HairFlow01'))-min(p[1] for p in positions('HairFlow02')))>.012,'Mira temple locks lose their intentional asymmetric silhouette'
  assert len(positions('CoatLapelLeft'))>30,'Mira lapel is still a flat cutout'
print('HERO_WARMTH_EXPORTED_CONTRACT passed')
