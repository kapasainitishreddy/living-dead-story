extends SceneTree
# Actual Godot frames; deliberately scripted fixtures, not a human playtest.
var game
var output := OS.get_environment("PLATFORM6_CAPTURE_DIR")
func _initialize(): call_deferred("run")
func capture(id: String):
	await RenderingServer.frame_post_draw
	var status = root.get_texture().get_image().save_png(output.path_join(id + ".png"))
	if status != OK: push_error("Cannot capture " + id)
func close():
	game.hud.close_all()
	game.resume_controls()
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	if output.is_empty(): output = "res://../evidence/opening-polish"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_capture_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	var prefs = game.model.snapshot().settings
	prefs.graphics = "low"
	game.change_settings(prefs)
	await create_timer(0.2).timeout
	await capture("01-apartment")
	if game.get("touch") != null:
		game.touch.set_touch_mode(true)
		await create_timer(0.2).timeout
		await capture("02-touch-exploration")
		game.touch.set_touch_mode(false)
	for action in ["leave_apartment", "meet_stranger", "read_board", "board_train"]: game.model.apply(action)
	game.route()
	close()
	game.player.position = Vector3(-1.8,0.05,1.2)
	await create_timer(0.2).timeout
	game.dispatch("dialogue", "train_window")
	await create_timer(0.12).timeout
	await capture("03-window-latch")
	await create_timer(1.0).timeout
	await capture("04-window-open")
	close()
	for item in [["meet_passenger",null],["arrive_shore",null],["assist",null],["choose_camera","unused"],["resolve_action","skipped"],["return_train",null]]: game.model.apply(item[0],item[1])
	game.route()
	close()
	await create_timer(0.2).timeout
	game.dispatch("dialogue", "breakfast_postcard")
	await create_timer(0.35).timeout
	await capture("05-postcard-turn")
	await create_timer(1.0).timeout
	await capture("06-postcard-reverse")
	close()
	prefs = game.model.snapshot().settings
	prefs.reduced_motion = true
	prefs.text_scale = 2.0
	game.change_settings(prefs)
	game.dispatch("dialogue", "breakfast_postcard")
	await create_timer(0.2).timeout
	await capture("07-reduced-motion-text2")
	close()
	game.audio.shutdown()
	game.queue_free()
	await process_frame
	await process_frame
	await process_frame
	print("OPENING POLISH CAPTURE COMPLETE ",RenderingServer.get_video_adapter_name())
	quit()
