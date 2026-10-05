"""Binary glTF contract checks for the two original skinned character assets.

This intentionally reads exported GLB data, not merely the generator's claims.
Run with ordinary Python, no Blender or third-party packages required.
"""
from pathlib import Path
import json, struct, hashlib, math

ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'game/assets/characters'
EXPECTED_BONES={'Root','Hips','Spine','Chest','Neck','Head','EyeLeft','EyeRight',
 'BrowLeft','BrowRight','Mouth','ShoulderLeft','ShoulderRight','UpperArmLeft',
 'UpperArmRight','ForearmLeft','ForearmRight','HandLeft','HandRight','ThighLeft',
 'ThighRight','ShinLeft','ShinRight','FootLeft','FootRight'}
COMPONENTS={5120:('b',1),5121:('B',1),5122:('h',2),5123:('H',2),5125:('I',4),5126:('f',4)}
WIDTHS={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}

def load(path):
    blob=path.read_bytes()
    assert struct.unpack_from('<III',blob)==(0x46546c67,2,len(blob)),path
    chunks=[];offset=12
    while offset<len(blob):
        n,kind=struct.unpack_from('<II',blob,offset);offset+=8
        chunks.append((kind,blob[offset:offset+n]));offset+=n
    gltf=json.loads(chunks[0][1]);binary=next(data for kind,data in chunks if kind==0x004e4942)
    return gltf,binary,blob

def accessor(g,b,idx):
    a=g['accessors'][idx];view=g['bufferViews'][a['bufferView']]
    fmt,size=COMPONENTS[a['componentType']];count=WIDTHS[a['type']]
    offset=view.get('byteOffset',0)+a.get('byteOffset',0);stride=view.get('byteStride',size*count)
    rows=[struct.unpack_from('<'+fmt*count,b,offset+i*stride) for i in range(a['count'])]
    if a.get('normalized'):
        divisor={5120:127,5121:255,5122:32767,5123:65535}[a['componentType']]
        rows=[tuple(max(-1,x/divisor) for x in row) for row in rows]
    return rows

def check_character(slug):
    path=DEST/slug/(slug+'.glb');g,b,blob=load(path)
    assert not g.get('images') and not g.get('textures'),'Unexpected external texture source'
    assert all('uri' not in buf for buf in g['buffers']),'External buffer'
    assert len(g['skins'])==1
    skin=g['skins'][0];bone_names={g['nodes'][i]['name'] for i in skin['joints']}
    assert bone_names==EXPECTED_BONES,(slug,bone_names^EXPECTED_BONES)
    names=[node['name'] for node in g['nodes'] if 'name' in node]
    assert len(names)==len(set(names)),'Colliding node names would rename Godot bones'
    assert all(g['nodes'][i].get('rotation',[0,0,0,1])==[0,0,0,1]
      for i in skin['joints'] if g['nodes'][i]['name'] in ['EyeLeft','EyeRight','BrowLeft','BrowRight','Mouth'])
    clips={a['name']:a for a in g['animations']};assert set(clips)=={'idle','walk'}
    duration={name:max(g['accessors'][s['input']]['max'][0] for s in a['samplers']) for name,a in clips.items()}
    assert math.isclose(duration['idle'],5,abs_tol=.00001)
    assert math.isclose(duration['walk'],1,abs_tol=.00001)
    positions=[];triangles=0;vertices=0;weight_rows=0
    for mesh in g['meshes']:
        for primitive in mesh['primitives']:
            attrs=primitive['attributes'];assert 'JOINTS_0' in attrs and 'WEIGHTS_0' in attrs
            vertices+=g['accessors'][attrs['POSITION']]['count']
            triangles+=g['accessors'][primitive['indices']]['count']//3
            positions+=accessor(g,b,attrs['POSITION'])
            weights=accessor(g,b,attrs['WEIGHTS_0']);joints=accessor(g,b,attrs['JOINTS_0'])
            for weight,joint in zip(weights,joints):
                assert abs(sum(weight)-1)<.0001,(slug,weight)
                assert all(0<=j<len(skin['joints']) for j,w in zip(joint,weight) if w>0)
            weight_rows+=len(weights)
    low=[min(p[i] for p in positions) for i in range(3)];high=[max(p[i] for p in positions) for i in range(3)]
    assert abs(low[1])<.000001,'Feet do not touch floor origin'
    assert abs(high[1]-1.7)<.00001,'Character height contract changed'
    front_nodes=[node for node in g['nodes'] if node.get('name')=='FacePupilLeft']
    assert len(front_nodes)==1
    front_primitive=g['meshes'][front_nodes[0]['mesh']]['primitives'][0]
    assert min(p[2] for p in accessor(g,b,front_primitive['attributes']['POSITION']))>0,'Face not +Z forward'
    assert (DEST/slug/'source'/f'{slug}.blend').exists(),'Editable Blender source missing'
    return {'glb':str(path.relative_to(ROOT)),'bytes':len(blob),'sha256':hashlib.sha256(blob).hexdigest(),
      'bones':sorted(bone_names),'mesh_nodes':len(g['meshes']),'export_vertices':vertices,
      'triangles':triangles,'verified_weight_rows':weight_rows,'bounds_min':low,'bounds_max':high,
      'clip_seconds':duration,'checks':'passed'}

if __name__=='__main__':
    results={slug:check_character(slug) for slug in ['protagonist','mira']}
    g,b,blob=load(DEST/'mira/camera.glb')
    assert not g.get('skins') and not g.get('animations'),'Camera must be unrigged and reusable'
    assert not g.get('textures') and not g.get('images')
    results['camera']={'glb':'game/assets/characters/mira/camera.glb','bytes':len(blob),
      'sha256':hashlib.sha256(blob).hexdigest(),'mesh_nodes':len(g['meshes']),'checks':'passed'}
    (DEST/'asset_validation.json').write_text(json.dumps(results,indent=2)+'\n')
    print(json.dumps(results,indent=2))
