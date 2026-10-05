extends SceneTree
var game
var camera: Camera3D
var out := "/workspace/shared/platform6-character-polish/evidence/characters/runtime"
func _initialize(): call_deferred("run")
func settle(seconds := 0.5):
	await create_timer(seconds).timeout
	await process_frame
func capture(id: String):
	await settle()
	root.get_texture().get_image().save_png(out+"/"+id+".png")
func view(from: Vector3, target: Vector3, fov := 34.0):
	camera = Camera3D.new()
	game.world_container.get_child(0).add_child(camera)
	camera.global_position = from
	camera.look_at(target)
	camera.fov = fov
	camera.current = true
func checkpoint(id: String):
	game.model.data.checkpoint_id = id
	game.route()
	game.hud.close_all()
	game.hud.hide()
	game.player.set_controls_enabled(false)
	await settle()
func run():
	if DisplayServer.get_name() == "headless":
		printerr("Character QA requires graphical renderer")
		quit(2)
		return
	if "baseline" in OS.get_cmdline_user_args(): out = out.replace("runtime","baseline")
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://character_rendered_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await settle()
	await checkpoint("conductor")
	game.player.position = Vector3(-1,0.05,2)
	game.player.visual.rotation.y = 0
	view(Vector3(-0.2,1.65,5),Vector3(-1,1.3,2),30)
	await capture("01-protagonist-close")
	view(Vector3(4.6,3.2,8),Vector3(0,1.3,-2),55)
	await capture("02-station-wide")
	view(Vector3(2.8,2.6,4.0),Vector3(-1,1.1,1),47)
	await capture("02b-station-readable-wide")
	await checkpoint("passenger")
	game.player.position = Vector3(-0.7,0.05,-1.7)
	game.player.visual.rotation.y = PI
	view(Vector3(2.2,1.65,-1.45),Vector3(1.8,1.37,-4),32)
	await capture("03-mira-close")
	view(Vector3(0.5,1.65,-1.45),Vector3(1.8,1.37,-4),32)
	await capture("03b-mira-listening-close")
	view(Vector3(0,2.25,2.9),Vector3(0.5,1.1,-3.0),50)
	await capture("04-carriage-two-shot")
	game.hud.show()
	for marker in game.world_container.get_child(0).get_children():
		if marker.get_meta("action_id","") == "meet_passenger": game.on_interact(marker)
	await capture("05-conversation-ui")
	print("CHARACTER_RENDERED_QA_DONE renderer=",RenderingServer.get_video_adapter_name())
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	quit()
