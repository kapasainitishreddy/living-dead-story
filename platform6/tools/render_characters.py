"""Rebuild orthographic studio evidence from the editable original .blend files."""
from pathlib import Path
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'game/assets/characters'
for slug in ['protagonist','mira']:
    bpy.ops.wm.open_mainfile(filepath=str(DEST/slug/'source'/f'{slug}.blend'))
    scene=bpy.context.scene
    rig=bpy.data.objects['Rig']
    for track in rig.animation_data.nla_tracks:track.mute=True
    rig.animation_data.action=None
    for p in rig.pose.bones:
        p.location=(0,0,0);p.rotation_euler=(0,0,0);p.scale=(1,1,1)
    bpy.context.view_layer.update()
    scene.render.engine='CYCLES';scene.cycles.samples=40;scene.cycles.use_denoising=False
    scene.render.threads_mode='FIXED';scene.render.threads=4
    scene.render.resolution_x=720;scene.render.resolution_y=880
    scene.camera.data.ortho_scale=1.96
    for suffix,pos in [('portrait',(2.5,-5,2.6)),('front',(0,-5,1.75)),('back',(2.5,5,2.1))]:
        cam=scene.camera;cam.location=pos
        cam.rotation_euler=(Vector((0,0,.855))-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(DEST/slug/f'{slug}_{suffix}.png')
        bpy.ops.render.render(write_still=True)
bpy.ops.wm.open_mainfile(filepath=str(DEST/'mira/source/camera.blend'))
bpy.context.scene.cycles.samples=40
bpy.context.scene.cycles.use_denoising=False
bpy.context.scene.render.filepath=str(DEST/'mira/camera_portrait.png')
bpy.ops.render.render(write_still=True)
