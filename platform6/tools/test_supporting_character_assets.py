"""Exported supporting-cast GLB/source contract. Run with ordinary Python.

The authored extension must preserve hero rig compatibility while delivering
individual silhouette/outfit geometry. Assertions read exported binary data.
"""
from pathlib import Path
import json, math, hashlib
from test_authored_character_assets import load, accessor, check_character, DEST, EXPECTED_BONES

ROOT=Path(__file__).resolve().parents[1]
CAST={
 'ada': {'SweptBunHair','LowWorkBun','WorkApron','ApronPocket','AgeCreaseLeft'},
 'noor': {'TuckedBobHair','GlassesFrameLeft','GlassesBridge','WorkApron','ApronPocket'},
 'rafi': {'CroppedWorkHair','WorkShirt','RolledCuffLeft','WorkPatchPocketLeft'},
 'conductor': {'UniformCoat','ConductorCapCrown','ConductorCapVisor','MoustacheLeft','UniformLapelLeft'},
 'jo': {'CoiledStationHair','StationWaistcoat','StationBadge','StationShirt'},
}

def check_cast(slug, markers):
    assert (DEST/slug/(slug+'.glb')).exists(),f'{slug}: original supporting-cast export missing'
    result=check_character(slug)
    g,b,blob=load(DEST/slug/(slug+'.glb'))
    nodes={n['name']:n for n in g['nodes'] if 'mesh' in n}
    assert markers<=set(nodes),f'{slug}: missing distinct authored silhouette/outfit {markers-set(nodes)}'
    names=[n['name'] for n in g['nodes'] if 'name' in n]
    assert not {'ScarfTail','MidnightJacket','BobHair','TerracottaCoat'} & set(nodes),f'{slug}: unchanged hero garment/hair slipped in'
    parents={c:i for i,node in enumerate(g['nodes']) for c in node.get('children',[])}
    by_name={n['name']:i for i,n in enumerate(g['nodes']) if 'name' in n}
    hero,hb,_=load(DEST/'protagonist/protagonist.glb')
    hp={c:i for i,n in enumerate(hero['nodes']) for c in n.get('children',[])}
    hi={n['name']:i for i,n in enumerate(hero['nodes']) if 'name' in n}
    for name in EXPECTED_BONES-{'Root'}:
        assert g['nodes'][parents[by_name[name]]]['name']==hero['nodes'][hp[hi[name]]]['name'],f'{slug}: bone parent {name}'
    for name in EXPECTED_BONES:
        for field in ['translation','rotation','scale']:
            assert g['nodes'][by_name[name]].get(field)==hero['nodes'][hi[name]].get(field),f'{slug}: rest-transform mismatch {name}/{field}'
    for node in nodes.values():
        for p in g['meshes'][node['mesh']]['primitives']:
            positions=accessor(g,b,p['attributes']['POSITION'])
            assert all(all(math.isfinite(x) for x in row) for row in positions),f'{slug}: non-finite vertex'
            assert len(positions)>=3
    def positions(name):
        primitive=g['meshes'][nodes[name]['mesh']]['primitives'][0]
        return accessor(g,b,primitive['attributes']['POSITION'])
    if slug=='noor':
        frame=g['meshes'][nodes['GlassesFrameLeft']['mesh']]['primitives'][0]
        ps=accessor(g,b,frame['attributes']['POSITION'])
        ix=[r[0] for r in accessor(g,b,frame['indices'])]
        volume=0.0
        for k in range(0,len(ix),3):
            p,q,r=[ps[j] for j in ix[k:k+3]]
            volume+=sum(p[i]*(q[(i+1)%3]*r[(i+2)%3]-q[(i+2)%3]*r[(i+1)%3]) for i in range(3))/6
        assert volume>0,'Noor: closed glasses-frame normals face inward'
    if slug in ['ada','noor']:
        assert min(p[1] for p in positions('ApronBib'))<=max(p[1] for p in positions('WorkApron'))+.002,f'{slug}: apron bib has visible waist gap'
    if slug=='rafi':
        for side in ['Left','Right']:
            assert min(p[1] for p in positions('ExposedWorkForearm'+side))<max(p[1] for p in positions('SkinHand'+side)),f'{slug}: detached wrist seam'
    assert result['triangles']<40000,f'{slug}: exceeds 40k triangle budget'
    assert result['bytes']<3_000_000,f'{slug}: exceeds 3MB GLB budget'
    face=g['meshes'][nodes['SculptedFace']['mesh']]['primitives'][0]
    result['face_geometry_sha256']=hashlib.sha256(str(accessor(g,b,face['attributes']['POSITION'])).encode()).hexdigest()
    result['authored_markers']=sorted(markers)
    return result

if __name__=='__main__':
    results={slug:check_cast(slug,markers) for slug,markers in CAST.items()}
    # Face positions differ, independently of material colors and filename.
    assert len({row['face_geometry_sha256'] for row in results.values()})==len(CAST),'Palette-only face reuse'
    manifest=json.loads((DEST/'supporting_cast_manifest.json').read_text())
    assert set(manifest['characters'])==set(CAST)
    assert manifest['external_assets']==[]
    assert manifest['palette_only_variants']==[]
    for slug in CAST:
        assert manifest['characters'][slug]['glb']==f'res://assets/characters/{slug}/{slug}.glb'
        assert len(manifest['characters'][slug]['individual_sculpt_changes'])>=3
    (DEST/'supporting_cast_validation.json').write_text(json.dumps(results,indent=2)+'\n')
    print(json.dumps(results,indent=2))
    print('SUPPORTING_CAST_EXPORT_CONTRACT passed')
