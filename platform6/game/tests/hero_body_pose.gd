extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,label: String):
 checks+=1
 if not ok:
  failures+=1
  printerr('FAIL: '+label)
func _initialize(): call_deferred('run')
func run():
 for id in ['protagonist','mira']:
  var actor=load('res://characters/character_performer.gd').new()
  actor.configure(id)
  root.add_child(actor)
  await process_frame
  actor.set_process(false)
  actor.apply_preferences(true)
  for side in ['Left','Right']:
   var hand=actor.skeleton.get_bone_global_pose(actor._bone_index('Hand'+side)).origin
   var elbow=actor.skeleton.get_bone_global_pose(actor._bone_index('Forearm'+side)).origin
   check(abs(hand.x)<.275 and abs(hand.x)>.215,id+' '+side+' hand rests near hip with cloth clearance')
   check(abs(elbow.x)<.26,id+' '+side+' elbow rests below shoulder without A-pose spread')
   var shoulder=actor.skeleton.get_bone_global_rest(actor._bone_index('UpperArm'+side)).origin
   var combined=shoulder.distance_to(elbow)+elbow.distance_to(hand)
   check(abs(combined-.458)<.012,id+' '+side+' relaxed posture preserves combined arm length')
  if id=='mira':
   await process_frame
   var nearest_front := 100.0
   for mesh in actor.get_attached_prop('camera').find_children('*','MeshInstance3D',true,false):
    var box=mesh.mesh.get_aabb()
    for i in range(8):
     var corner=box.position+Vector3(box.size.x if i&1 else 0.0,box.size.y if i&2 else 0.0,box.size.z if i&4 else 0.0)
     var point=actor.to_local(mesh.global_transform*corner)
     nearest_front=minf(nearest_front,point.z)
   print('MIRA_CAMERA_FORWARD_CLEARANCE ',nearest_front)
   check(nearest_front>.075,'Mira camera rests ahead of the front coat surface')
  actor.set_locomotion(1.3165)
  for i in range(120):actor.advance_performance(1.0/60.0)
  var first=actor.skeleton.get_bone_pose_rotation(actor._bone_index('UpperArmLeft'))
  actor.advance_performance(.2)
  check(first.angle_to(actor.skeleton.get_bone_pose_rotation(actor._bone_index('UpperArmLeft')))>.025,id+' relaxed arm still swings during walking')
  actor.queue_free()
  await process_frame
 print('HERO_BODY_POSE ',checks,' checks; failures: ',failures)
 quit(1 if failures else 0)
