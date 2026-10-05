"""Rebuild cast studio evidence from editable sources without re-exporting."""
from pathlib import Path
import sys
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'game/assets/characters'
slugs=[sys.argv[sys.argv.index('--only')+1]] if '--only' in sys.argv else ['ada','noor','rafi','conductor','jo']
for slug in slugs:
    bpy.ops.wm.open_mainfile(filepath=str(DEST/slug/'source'/f'{slug}.blend'))
    scene=bpy.context.scene;rig=bpy.data.objects['Rig']
    for track in rig.animation_data.nla_tracks:track.mute=True
    rig.animation_data.action=None
    for p in rig.pose.bones:p.location=(0,0,0);p.rotation_euler=(0,0,0);p.scale=(1,1,1)
    bpy.context.view_layer.update()
    scene.render.engine='CYCLES';scene.cycles.samples=16;scene.cycles.use_denoising=False
    scene.render.threads_mode='FIXED';scene.render.threads=2
    scene.render.resolution_x=500;scene.render.resolution_y=650
    scene.camera.data.ortho_scale=1.91
    for suffix,pos in [('portrait',(1.6,-5,2.15)),('back',(2.3,5,2.1))]:
        cam=scene.camera;cam.location=pos
        cam.rotation_euler=(Vector((0,0,.855))-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(DEST/slug/f'{slug}_{suffix}.png')
        bpy.ops.render.render(write_still=True)
    print('CAST_RENDER_COMPLETE',slug,flush=True)
