extends SceneTree
var failures := 0
func _initialize(): call_deferred('run')
func run():
 for id in ['mira','protagonist']:
  var actor = load('res://characters/character_performer.gd').new()
  actor.configure(id)
  root.add_child(actor)
  await process_frame
  actor.set_process(false)
  actor.set_conversation(true)
  actor.conversation_blend = 1.0
  actor.elapsed = 3.5
  actor.advance_performance(0.0)
  var first = actor.skeleton.get_bone_pose_rotation(actor._bone_index('Mouth'))
  actor.elapsed = 6.0
  actor.advance_performance(0.0)
  var second = actor.skeleton.get_bone_pose_rotation(actor._bone_index('Mouth'))
  if first.angle_to(second)<0.004:
   failures+=1
   printerr('FAIL: '+id+' listening smile never softens between acknowledgement holds')
  actor.apply_preferences(true)
  # Inspect immediately, before any new frame/advance can conceal a stale pose.
  if actor.skeleton.get_bone_pose_rotation(actor._bone_index('Mouth')).get_angle()>.0001:
   failures+=1
   printerr('FAIL: '+id+' reduced motion did not immediately settle the mouth')
  for bone in ['BrowLeft','BrowRight']:
   if actor.skeleton.get_bone_pose_rotation(actor._bone_index(bone)).get_angle()>.0001:
    failures+=1
    printerr('FAIL: '+id+' reduced motion did not immediately settle '+bone)
  var reduced_first = actor.skeleton.get_bone_pose_rotation(actor._bone_index('Mouth'))
  actor.elapsed = 9.0
  actor.advance_performance(0.0)
  if reduced_first.angle_to(actor.skeleton.get_bone_pose_rotation(actor._bone_index('Mouth')))>.0001:
   failures+=1
   printerr('FAIL: '+id+' reduced motion animates the mouth')
  actor.queue_free()
  await process_frame
 print('HERO_EXPRESSION 10 checks; failures: ',failures)
 quit(1 if failures else 0)
