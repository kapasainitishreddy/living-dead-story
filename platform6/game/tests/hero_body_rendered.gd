extends SceneTree
var checks:=0
var failures:=0
var out='res://../evidence/body/gestures'
func _initialize():call_deferred('run')
func check(ok:bool,label:String):
 checks+=1
 if not ok:
  failures+=1
  printerr('FAIL: '+label)
func capture(label:String):
 await process_frame
 await process_frame
 var pic=root.get_texture().get_image()
 check(not pic.is_empty() and pic.save_png(out+'/'+label+'.png')==OK,'actual pixels '+label)
 var colors={}
 for y in range(0,pic.get_height(),24):
  for x in range(0,pic.get_width(),24):colors[pic.get_pixel(x,y).to_html(false)]=true
 check(colors.size()>32,'capture contains the scene rather than a wall '+label)
func close_camera(world,actor):
 var cam=Camera3D.new()
 world.add_child(cam)
 cam.global_position=actor.global_position+Vector3(-1.3,1.5,3.1)
 cam.look_at(actor.global_position+Vector3(0,1.05,0))
 cam.fov=38
 cam.current=true
 return cam
func run():
 if DisplayServer.get_name()=='headless':quit(2);return
 out=ProjectSettings.globalize_path(out)
 DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(1280,720)
 for choice in ['luck','joke','thanks','wave','little']:
  var world=load('res://world/return_world.gd').new().build({'return_checkpoint':'departed','return_state':{'farewell':choice},'camera_choice':'lend','settings':{'reduced_motion':false}})
  root.add_child(world)
  await process_frame
  world.set_process(false)
  world.begin_departure(choice,'lend')
  world._process(.65)
  world.mira.set_process(false)
  close_camera(world,world.mira)
  await capture('farewell-'+choice)
  if choice=='wave':
   world.cinematic_phase='preparation'
   world._pose_actor(0.0,1.0,1.0,1.0)
   await capture('tool-lift-strap-adjust')
   world.cinematic_phase='camera_slip'
   world.camera_slip=1.0
   world._pose_actor(0.0,1.0,0.0,0.0)
   await capture('camera-slip-extreme')
   world.cinematic_phase='camera_catch'
   world.camera_slip=0.0
   world._pose_actor(0.0,1.0,0.0,0.0)
   await capture('camera-caught')
  world.free()
 var helper=load('res://tests/full_campaign.gd').new()
 var seed=helper.completed_return('lend','skipped')
 helper.free()
 var game=load('res://main.tscn').instantiate()
 game.save_path='user://body_seat_'+str(Time.get_ticks_usec())+'.json'
 root.add_child(game)
 await process_frame
 check(game.model.restore(seed),'valid completed-return source')
 game.route()
 game.dispatch('begin_home')
 game.dispatch('home_ticket','kettle')
 game.dispatch('home_ritual','window')
 await process_frame
 var home=game.world_container.get_child(0)
 var sitter=home.get_node('WindowSitter')
 game.hud.hide()
 check(sitter.visible and game.home_viewing,'actual seated view remains in apartment')
 var cam=Camera3D.new();home.add_child(cam)
 cam.global_position=sitter.global_position+Vector3(1.8,1.8,-1.5)
 cam.look_at(sitter.global_position+Vector3(0,.95,0));cam.fov=42;cam.current=true
 await capture('home-seated-relaxed-hands')
 for side in ['Left','Right']:
  var hand=sitter.skeleton.get_bone_global_pose(sitter._bone_index('Hand'+side)).origin
  var hips=sitter.skeleton.get_bone_global_pose(sitter._bone_index('Hips')).origin
  check(abs(hand.x)>.215 and hand.y>hips.y+.015,'seated '+side+' hand remains outside lap centre and above seat')
 game.audio.shutdown()
 await create_timer(.25).timeout
 game.queue_free()
 await process_frame
 await process_frame
 game=null
 home=null
 sitter=null
 cam=null
 print('HERO_BODY_RENDERED ',checks,' checks; failures: ',failures)
 quit(1 if failures else 0)
