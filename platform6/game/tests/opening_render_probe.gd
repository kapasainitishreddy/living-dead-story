extends SceneTree
var game
func _initialize(): call_deferred("run")
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_probe_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await create_timer(0.4).timeout
	var out = "res://../evidence/opening/"+OS.get_environment("OPENING_STAGE")
	DirAccess.make_dir_recursive_absolute(out)
	root.get_texture().get_image().save_png(out+"/01-opening.png")
	game.hud.close_all()
	game.hud.hide()
	game.player.set_controls_enabled(false)
	var camera = Camera3D.new()
	game.world_container.get_child(0).add_child(camera)
	camera.position = Vector3(7.8,3.6,6.5)
	camera.look_at(Vector3(-2,1.4,-5.5))
	camera.fov = 55
	camera.current = true
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(out+"/02-wide.png")
	game.dispatch("leave_apartment")
	game.dispatch("meet_stranger")
	game.dispatch("read_board")
	game.dispatch("board_train")
	game.hud.close_all()
	game.hud.hide()
	await create_timer(0.3).timeout
	root.get_texture().get_image().save_png(out+"/03-train.png")
	print("OPENING_PROBE_COMPLETE ",RenderingServer.get_video_adapter_name())
	game.audio.shutdown()
	await create_timer(0.25).timeout
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	await create_timer(0.2).timeout
	quit()
