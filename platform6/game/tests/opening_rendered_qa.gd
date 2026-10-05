extends SceneTree
var game
var checks := 0
var failures := 0
var report := {"views":[],"renderer":"","limits":"Actual cloud Compatibility renderer with synthetic keyboard/gamepad input. Physical controllers, target devices, human audio acceptance and shipping quality unverified."}
var out := "res://../evidence/opening/rendered"
func _initialize(): call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; printerr("FAIL "+label)
func settle():
	await create_timer(0.20).timeout
	await process_frame
func capture(id: String):
	await settle()
	check(root.get_texture().get_image().save_png(out+"/"+id+".png") == OK,"saved actual pixels "+id)
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(out)
	root.size = Vector2i(1280,720)
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_rendered_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await settle()
	for tier in ["low","medium","high"]:
		var settings = game.model.snapshot().settings
		settings.graphics = tier
		game.change_settings(settings)
		await settle()
		await capture("opening-"+tier)
		check(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) < 500,"bounded rendered draw calls "+tier)
		var ticks := []
		var last = Time.get_ticks_usec()
		for i in range(60):
			await process_frame
			var now = Time.get_ticks_usec()
			ticks.append(float(now-last)/1000.0)
			last = now
		ticks.sort()
		report.views.append({"tier":tier,"frame_wall_ms_median":ticks[30],"frame_wall_ms_p95":ticks[57],"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)})
	var world = game.world_container.get_child(0)
	var prefs = game.model.snapshot().settings
	prefs.reduced_motion = true
	prefs.text_scale = 2.0
	game.change_settings(prefs)
	check(not world.get_node("Rain").visible,"actual reduced-motion apartment hides rain")
	await capture("opening-reduced-motion")
	game.show_pause()
	await capture("opening-pause-text2")
	check(game.hud.pause_active and not game.player.enabled,"native renderer pause disables exploration")
	game.hud.resume_pause()
	game.hud.close_all()
	game.resume_controls()
	game.player.position = Vector3(0,0.12,-6.85)
	for i in range(8): await physics_frame
	check(game.player.nearest != null and game.player.nearest.get_meta("action_id") == "leave_apartment","actual physics reaches original opening exit")
	game.on_interact(game.player.nearest)
	check(game.hud.modal_visible(),"exit opens authored confirmation")
	game.hud.footer.get_child(0).pressed.emit()
	check(game.model.snapshot().checkpoint_id == "roof","native rendered exit progresses to roof")
	await capture("roof-after-original-exit")
	report.renderer = RenderingServer.get_video_adapter_name()
	report.checks = checks
	report.failures = failures
	var file = FileAccess.open(out+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	game.audio.shutdown()
	await create_timer(0.25).timeout
	game.queue_free()
	await process_frame
	await process_frame
	game = null
	print("OPENING_RENDERED_QA ",checks," checks; failures: ",failures)
	quit(1 if failures else 0)
