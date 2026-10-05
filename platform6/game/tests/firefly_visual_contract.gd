extends SceneTree
var checks=0
var failures=0
func check(ok,label):
 checks+=1
 if not ok: failures+=1;printerr('FAIL '+label)
func _initialize(): call_deferred('run')
func run():
 var pack=JSON.parse_string(FileAccess.get_file_as_string('res://data/journey_pack.json'))
 var d=pack.destinations.filter(func(item):return item.journey_id=='fireflies')[0]
 for visits in [0,1]:
  var state={'mode':'destination','journey_id':'fireflies','visits':{'fireflies':visits},'location_states':{'fireflies':'star_line' if visits else 'as_found'},'activity':{}}
  var world=load('res://world/journey_world.gd').new().build(state,{'settings':{'reduced_motion':false}},d)
  root.add_child(world);await physics_frame
  var art=world.get_node('Scenery/PaintedClearing')
  check(art.has_node('PaintedMeadow') and art.has_node('WindingFootpath'),'original continuous ground and blended path')
  check(art.has_node('PaintedAlderCanopies'),'painted alpha foliage exists in actual world')
  check(art.get_node('PaintedAlderCanopies').multimesh.instance_count==108,'bounded instanced trees and natural perimeter brush')
  check(art.has_node('RailwayEmbankment') and art.has_node('EveningTrain'),'train grounded on railway embankment')
  check(art.get_node('EveningTrain').find_children('Wheel*','MeshInstance3D',true,false).size()==6,'distant train has six actual wheels')
  check(world.get_node('Interactions/journey_activity').get_meta('label')=='Trace the stars','close cue fits instead of clipped full instruction')
  check(not world.get_node('Ground').get_child(0).visible,'floor collision retains invisible proxy behind scenic floor')
  check(world.get_node('Ground') is StaticBody3D and world.get_node('BoundaryBack') is StaticBody3D,'physical boundary contract retained')
  check(not world.get_node('BoundaryBack').get_child(0).visible,'box fence not presented')
  check(world.find_children('*','Node',true,false).size()<650,'bounded scenic node count')
  check(world.get_node('Scenery/NPCIndependentState').visibility_range_end==4.0,'NPC copy is contextual close range')
  world.apply_preferences(true)
  var rests=world._decorative.map(func(i):return i.node.position)
  world._process(1.0)
  check(rests==world._decorative.map(func(i):return i.node.position),'reduced motion holds every firefly at rest')
  world.set_paused(true);check(world.paused,'scene pause preserved')
  world.free();await physics_frame
 print('FIREFLY VISUAL CONTRACT ',checks,' checks ',failures,' failures')
 quit(1 if failures else 0)
