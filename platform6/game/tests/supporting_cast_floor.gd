extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok: failures+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
 var model=load("res://core/chapter_model.gd").new()
 var world=load("res://world/orchard_world.gd").new().build(model.snapshot())
 root.add_child(world); await process_frame; await process_frame
 var actor=world.get_node("Cart/SeatedRider/SupportingPerformer")
 actor.set_process(false); actor.apply_preferences(true); actor.advance_performance(0)
 var deck_top=world.get_node("Cart/Deck").global_position.y+.09
 var hips=actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(actor._bone_index("Hips")).origin
 var seat_top=world.get_node("Cart/Seat").global_position.y+.06
 check(abs(hips.y-seat_top)<.035,"articulation preserves hips at actual cart seat")
 var soles:=0
 for node in actor.model.find_children("*","MeshInstance3D",true,false):
  if not str(node.name).begins_with("Sneaker") or not str(node.name).contains("Sole"): continue
  soles+=1
  var min_y=INF
  for surface in node.mesh.get_surface_count():
   var arrays=node.mesh.surface_get_arrays(surface)
   var verts=arrays[Mesh.ARRAY_VERTEX];var binds=arrays[Mesh.ARRAY_BONES];var weights=arrays[Mesh.ARRAY_WEIGHTS]
   for i in verts.size():
    var point=Vector3.ZERO
    for j in 4:
     var index=int(binds[i*4+j]);var bone=node.skin.get_bind_bone(index)
     if bone<0:bone=actor.skeleton.find_bone(node.skin.get_bind_name(index))
     point+=(actor.skeleton.global_transform*actor.skeleton.get_bone_global_pose(bone)*node.skin.get_bind_pose(index)*verts[i])*weights[i*4+j]
    min_y=minf(min_y,point.y)
  print("CART_SOLE ",node.name," y=",min_y," deck_top=",deck_top)
  check(min_y>=deck_top-.005,"actual skinned "+str(node.name)+" clears existing cart deck")
 check(soles==2,"both real exported shoe soles were measured")
 world.queue_free();await process_frame;await process_frame
 print("SUPPORTING_CAST_FLOOR ",checks," checks; failures: ",failures);quit(1 if failures else 0)
