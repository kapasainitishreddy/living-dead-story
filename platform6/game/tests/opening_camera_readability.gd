extends SceneTree
var checks:=0
var failures:=0
func check(ok:bool,label:String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,720);root.content_scale_size=Vector2i(1280,720)
 for action in ["look_left","look_right","look_up","look_down","move_left","move_right","move_forward","move_back"]:
  if not InputMap.has_action(action):InputMap.add_action(action)
 var world=load("res://world/world_factory.gd").new().build("roof")
 root.add_child(world)
 var player=load("res://player/player.gd").new();world.add_child(player);player.position=Vector3(0,.1,5)
 await process_frame
 check(player.arm.spring_length>=3.5 and player.arm.spring_length<=4.3,"closer exploration camera keeps meaningful scenery scale")
 check(player.arm.get_child(0).fov<=56,"calmer focal length reduces giant room/cube perspective")
 check(player.pivot.position.x>.35 and player.pivot.position.x<.9,"shoulder offset leaves the interaction speaker visible")
 check(player.has_node("ContactShadow"),"actual protagonist has restrained contact grounding")
 check(player.has_method("frame_speaker"),"conversation can frame actual speaker instead of fixed arbitrary yaw")
 if player.has_method("frame_speaker"):
  var target=Node3D.new();world.add_child(target);target.position=Vector3(3,0,1)
  player.preferences.reduced_motion=true
  var yaw=player.pivot.rotation.y;player.set_framed_view(true);player.frame_speaker(target)
  check(player.pivot.rotation.y==yaw,"reduced motion never auto-pans toward speaker")
  player.set_framed_view(false)
  player.preferences.reduced_motion=false
  player.set_framed_view(true);player.frame_speaker(target)
  await create_timer(.5).timeout
  var camera=root.get_camera_3d()
  var head=camera.unproject_position(target.global_position+Vector3(0,1.6,0))
  check(head.y<250,"actual speaker head is visible above lower dialogue panel")
  check(not player.visual.visible,"portrait framing cannot be blocked by close protagonist mesh")
  player.set_framed_view(false)
  check(player.visual.visible and player.arm.get_child(0).current,"Back restores exactly one player and its exploration camera")
 world.queue_free();await process_frame;await process_frame
 print("OPENING_CAMERA ",checks," checks; failures: ",failures);quit(1 if failures else 0)
