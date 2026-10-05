"""Original rounded furniture contours for the existing apartment; metres and editable."""
from pathlib import Path
import bpy, math
ROOT=Path(__file__).resolve().parents[1]/'game/art/apartment'
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
def material(name,c):
 m=bpy.data.materials.new(name); m.diffuse_color=(*c,1); m.use_nodes=True
 m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=(*c,1)
 m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.94
 return m
wood=material('Original warm oak',(.60,.44,.30)); linen=material('Original sea green linen',(.45,.58,.53)); cream=material('Original worn pillow',(.85,.81,.68)); terra=material('Original rust throw',(.62,.43,.32))
def soft(name,pos,size,bevel,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=(pos[0],-pos[2],pos[1]))
 ob=bpy.context.object; ob.name=name; ob.dimensions=(size[0],size[2],size[1]); bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 ob.data.materials.append(mat)
 mod=ob.modifiers.new('Authored softly worn edges','BEVEL'); mod.width=bevel; mod.segments=4
 bpy.ops.object.modifier_apply(modifier=mod.name)
 for poly in ob.data.polygons: poly.use_smooth=True
 mod=ob.modifiers.new('Weighted linen and wood normals','WEIGHTED_NORMAL'); mod.keep_sharp=True
 bpy.ops.object.modifier_apply(modifier=mod.name)
 return ob
soft('OakTabletop',(4,1.355,-3),(3.06,.10,1.66),.04,wood)
for z in [-3.69,-2.31]: soft('OakApron',(4,1.14,z),(2.89,.31,.085),.018,wood)
for x in [2.61,5.39]:
 soft('OakApronSide',(x,1.14,-3),(.10,.31,1.41),.018,wood)
 for z in [-3.61,-2.39]: soft('TaperedTableLeg',(x,.55,z),(.13,1.08,.13),.021,wood)
soft('RoundedDuvet',(-4,1.027,-1.10),(3.08,.23,2.65),.11,linen)
soft('SoftPillow',(-4,1.041,-3.5),(2,.28,.86),.13,cream)
soft('FoldedThrow',(-4,1.175,-.42),(3.10,.10,.64),.04,terra)
for x in [-5.10,-4.4,-3.8,-3.0]:
 soft('LinenQuiltSeam',(x,1.145,-1.40),(.012,.003,1.68),.001,cream)
ROOT.mkdir(parents=True,exist_ok=True)
(ROOT/'source').mkdir(exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source/apartment_furniture.blend'))
bpy.ops.export_scene.gltf(filepath=str(ROOT/'apartment_furniture.glb'),export_format='GLB',export_apply=True)
print('ORIGINAL_APARTMENT_FURNITURE',len(bpy.data.objects),'objects')
