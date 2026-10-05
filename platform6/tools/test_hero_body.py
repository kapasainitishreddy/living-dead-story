from test_authored_character_assets import load,accessor,DEST,check_character
for slug in ['protagonist','mira']:
 g,b,_=load(DEST/slug/(slug+'.glb'));nodes={n['name']:n for n in g['nodes'] if 'mesh' in n}
 def data(name,field):return accessor(g,b,g['meshes'][nodes[name]['mesh']]['primitives'][0]['attributes'][field])
 parents={child:i for i,node in enumerate(g['nodes']) for child in node.get('children',[])}
 by_name={node['name']:i for i,node in enumerate(g['nodes']) if 'name' in node}
 for side in ['Left','Right']:
  for child,parent in [('Shoulder','Chest'),('UpperArm','Shoulder'+side),('Forearm','UpperArm'+side),('Hand','Forearm'+side),('Thigh','Hips'),('Shin','Thigh'+side),('Foot','Shin'+side)]:
   assert g['nodes'][parents[by_name[child+side]]]['name']==parent,'Retained articulated bone parent changed'
 neck=data('SkinNeck','POSITION')
 assert max(abs(p[0]) for p in neck if p[1]>1.34)<.048,'Neck retains a wide cylindrical plug beneath the chin'
 assert len(data('CoatSleeveLeft' if slug=='mira' else 'JacketSleeveLeft','POSITION'))>320,'Sleeve remains a coarse tubular loft at elbow'
 check_character(slug)
print('HERO_BODY_EXPORTED_CONTRACT passed')
