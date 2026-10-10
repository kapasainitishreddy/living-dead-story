extends SceneTree
# Real renderer captures of canonical fixtures; no independent human play claim.
var game
var output := OS.get_environment("PLATFORM6_CAPTURE_DIR")
var fixtures = preload("res://tests/illustrated_fixtures.gd").new()
func _initialize(): call_deferred("run")
func close():
	game.hud.close_all()
	game.resume_controls()
func picture(id: String):
	close()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(output.path_join(id+".png")) != OK: push_error("Capture failed " + id)
	# Hold each rendered location long enough to read in the optional movie.
	for frame in range(24):
		await process_frame
		await RenderingServer.frame_post_draw
	var world = game.world_container.get_child(0)
	var art = world.get_node_or_null("IllustratedWorld")
	print("ILLUSTRATED FRAME ",id," details=",art.get_meta("added_triangles") if art != null else 0," draws=",root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)," triangles=",root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	if output.is_empty(): output = "res://../evidence/illustrated"
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://illustrated_capture_"+str(Time.get_ticks_usec())+".json"
	game.journey_save_path = "user://illustrated_capture_journey_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await process_frame
	await RenderingServer.frame_post_draw
	for entry in fixtures.entries:
		var snapshot: Dictionary = entry.snapshot.duplicate(true)
		snapshot.settings.graphics = "medium"
		snapshot.settings.reduced_motion = true
		if not game.model.restore(snapshot): push_error("Cannot restore " + entry.id)
		game.route(false)
		await picture(entry.id)
		if entry.id == "04-carriage":
			game.player.position = Vector3(-1.8,0.05,1.2)
			close()
			game.dispatch("dialogue","train_window")
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("04b-window-interaction.png"))
	var completed = fixtures.completed.duplicate(true)
	completed.settings.graphics = "medium"
	completed.settings.reduced_motion = true
	game.model.restore(completed)
	game.journey.active = true
	game.journey.model = load("res://core/journey_model.gd").new()
	game.route(false)
	await picture("13-journey-train")
	var index := 14
	for destination in game.journey.model.destinations():
		game.journey.model.apply("return_train")
		if not game.journey.model.apply("board",destination.journey_id): push_error("Cannot board " + destination.journey_id)
		game.route(false)
		await picture(str(index)+"-"+destination.journey_id)
		index += 1
	game.audio.shutdown()
	game.journey.profile_player.stop()
	game.queue_free()
	game = null
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	print("ILLUSTRATED CAPTURE COMPLETE ",RenderingServer.get_video_adapter_name())
	quit()
