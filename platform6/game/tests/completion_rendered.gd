extends SceneTree
var game
var out := ""
func _initialize(): call_deferred("run")
func settle():
 for i in 12: await process_frame
 await RenderingServer.frame_post_draw
func view(from: Vector3, target: Vector3, fov := 43.0):
 var world = game.world_container.get_child(0)
 for camera in world.find_children("CompletionCamera*","Camera3D",true,false): camera.queue_free()
 var camera = Camera3D.new()
 camera.name = "CompletionCamera"
 world.add_child(camera)
 camera.global_position = from
 camera.look_at(target)
 camera.fov = fov
 camera.current = true
func capture(id: String):
 await settle()
 root.get_texture().get_image().save_png(out+"/"+id+".png")
func quiet():
 game.hud.close_all(); game.hud.hide()
 game.player.set_controls_enabled(false)
 for label in game.world_container.get_child(0).find_children("*","Label3D",true,false): label.hide()
func chapter(id: String):
 game.model = load("res://core/chapter_model.gd").new()
 game.model.data.checkpoint_id = id
 game.route(); quiet(); await settle()
func run():
 if DisplayServer.get_name() == "headless": quit(2); return
 var stage = OS.get_environment("COMPLETION_STAGE")
 if stage.is_empty(): stage="after"
 out=ProjectSettings.globalize_path("res://../evidence/completion/"+stage)
 DirAccess.make_dir_recursive_absolute(out)
 root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720)
 game=load("res://main.tscn").instantiate()
 game.save_path="user://completion-render-"+str(Time.get_ticks_usec())+".json"
 root.add_child(game); await settle()
 var group=OS.get_environment("COMPLETION_GROUP")
 if group.is_empty() or group=="opening":
  await chapter("roof")
  view(Vector3(2.2,2.1,0),Vector3(0,1.15,-4),37); await capture("01-roof-stranger")
  await chapter("conductor")
  view(Vector3(3.8,2.05,0),Vector3(2,1.25,-4),37); await capture("02-conductor")
  view(Vector3(-5.5,3.4,9),Vector3(-0.5,2,-1),58); await capture("03-station")
  await chapter("passenger")
  view(Vector3(0,2.25,2.9),Vector3(0.5,1.1,-3),50); await capture("04-carriage")
  await chapter("overlook")
  view(Vector3(8,4,9),Vector3(0,1,-2),58); await capture("05-shore")
 if group.is_empty() or group=="cast":
  var helper=load("res://tests/kitchen_rendered_qa.gd").new()
  game.model.restore(helper.seed_paper()); helper.free()
  game.model.data.campaign_chapter="paper_sky"
  game.route(); quiet(); await settle()
  view(Vector3(-1.8,2.05,1.4),Vector3(-3.58,1.1,-3.39),37); await capture("06-noor")
  view(Vector3(5.4,1.8,-0.7),Vector3(5.23,1.1,-2.75),37); await capture("07-rafi")
  game.dispatch("begin_kitchen"); quiet(); await settle()
  view(Vector3(2.3,2.5,3.5),Vector3(-0.6,1.3,-1.3),50); await capture("08-kitchen")
  view(Vector3(-0.7,2.0,2.0),Vector3(-3.2,1.15,-0.51),37); await capture("09-ada")
 if group.is_empty() or group=="return":
  var return_helper=load("res://tests/return_runtime.gd").new()
  game.model.restore(return_helper.orchard_seed("lend")); return_helper.free()
  game.route(); game.dispatch("begin_return"); quiet(); await settle()
  view(Vector3(-3.6,1.8,7.2),Vector3(-5.7,1.25,10.9),48); await capture("10-jo-seated")
 if group=="orchard":
  var helper=load("res://tests/return_runtime.gd").new()
  game.model.restore(helper.orchard_seed("lend")); helper.free()
  game.model.data.orchard.route="cart"
  game.route(); quiet(); await settle()
  var world=game.world_container.get_child(0)
  world.set_rest_view(true)
  var rider=world.get_node("Cart/SeatedRider").global_position
  view(rider+Vector3(2.0,2.1,-2.7),rider+Vector3(0,1.0,0),46); await capture("11-orchard-cart-seated")
  var worker=world.get_node("Workers").get_child(0).global_position
  view(worker+Vector3(3.4,1.6,1.4),worker+Vector3(0,1.0,0),40); await capture("12-orchard-workers")
 print("COMPLETION_RENDERED_DONE stage=",stage," renderer=",RenderingServer.get_video_adapter_name())
 game.audio.shutdown(); await create_timer(0.2).timeout
 game.queue_free(); await process_frame; await process_frame; game=null; quit()
