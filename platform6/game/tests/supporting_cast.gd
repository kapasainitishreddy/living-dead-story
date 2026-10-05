extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
 checks += 1
 if not ok: failures += 1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
 check(ResourceLoader.exists("res://characters/supporting_performer.gd"),"supporting cast has compatible original rig presentation")
 if failures: print("SUPPORTING_CAST ",checks," checks; failures: ",failures); quit(1); return
 var factory=load("res://world/world_factory.gd").new()
 for id in ["ada","noor","rafi","conductor","jo"]:
  var owner=Node3D.new(); owner.name=id.capitalize(); owner.set_meta("character_id",id)
  root.add_child(owner)
  factory.person(owner,Vector3.ZERO,Color("ccac88"))
  var star=MeshInstance3D.new(); star.name="CrookedPaperStar"; star.mesh=QuadMesh.new(); owner.add_child(star)
  owner.get_node("HairBun").visible=true
  await process_frame; await process_frame
  var actor=owner.get_node_or_null("SupportingPerformer")
  check(actor!=null,id+" replaces visible primitive body")
  if actor==null: owner.queue_free(); await process_frame; continue
  actor.set_process(false)
  actor.apply_preferences(true)
  check(star.is_visible_in_tree(),id+" named meaningful paper-star prop remains visible")
  check(actor.character_id==id,id+" retains its distinct identity")
  check(actor.skeleton!=null and actor.skeleton.get_bone_count()==25,id+" uses compatible complete skeleton")
  check(actor.animation_tree!=null,id+" retains functional locomotion and microacting")
  for part in ["Coat","Hair","HairBun","Satchel","ArmLeft","ArmRight","LegLeft","LegRight"]:
   check(owner.has_node(part),id+" preserves chapter staging handle "+part)
   check(not owner.get_node(part).visible,id+" primitive "+part+" is absent from visible cast")
  actor.advance_performance(0.0)
  var arm=actor._bone_index("UpperArmLeft")
  var rest=actor.skeleton.get_bone_pose_rotation(arm)
  owner.get_node("ArmLeft").rotation.x=-0.8
  actor.advance_performance(0.0)
  check(rest.angle_to(actor.skeleton.get_bone_pose_rotation(arm))>.7,id+" chapter-owned serving/carrying pose drives actual arm")
  owner.get_node("ArmLeft").rotation=Vector3.ZERO
  owner.get_node("LegLeft").rotation.x=-PI/2
  owner.get_node("LegRight").rotation.x=-PI/2
  actor.advance_performance(0.0)
  var knee=actor.skeleton.get_bone_global_pose(actor._bone_index("ShinLeft")).origin
  var hip=actor.skeleton.get_bone_global_pose(actor._bone_index("ThighLeft")).origin
  var ankle=actor.skeleton.get_bone_global_pose(actor._bone_index("FootLeft")).origin
  check(knee.z>hip.z+.25 and abs(knee.y-hip.y)<.045,id+" seated thigh points forward instead of hanging through bench")
  check(ankle.y<knee.y-.25 and abs(ankle.z-knee.z)<.07,id+" seated shin counter-rotates downward")
  var seated_pose=actor.skeleton.get_bone_pose_rotation(actor._bone_index("ThighLeft"))
  actor.apply_preferences(false)
  check(seated_pose.angle_to(actor.skeleton.get_bone_pose_rotation(actor._bone_index("ThighLeft")))<.03,id+" live preferences preserve actual seated posture immediately")
  check(actor.position.is_zero_approx(),id+" acting cannot move chapter root or collisions")
  owner.queue_free(); await process_frame
 print("SUPPORTING_CAST ",checks," checks; failures: ",failures)
 quit(1 if failures else 0)
