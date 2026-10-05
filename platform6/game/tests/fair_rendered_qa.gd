extends SceneTree
var game
var failures := 0
var checks := 0
var out := "res://../evidence/fair/rendered"
func check(ok: bool, label: String):
	checks += 1
	print("QA ","PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func settle():
	await create_timer(0.25).timeout
	await process_frame
func capture(id: String):
	await settle()
	root.get_texture().get_image().save_png(out+"/"+id+".png")
func act(action: String, value: Variant = null):
	game.dispatch(action,value)
	while game.racing: await process_frame
	await settle()
func run():
	if DisplayServer.get_name() == "headless":
		printerr("Requires actual graphical Godot renderer")
		quit(2)
		return
	out = OS.get_environment("FAIR_QA_OUT") if not OS.get_environment("FAIR_QA_OUT").is_empty() else ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://fair_rendered_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await settle()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]:
		await act(action)
	await act("choose_camera","lend")
	await act("resolve_action","skipped")
	for action in ["return_train","have_breakfast","finish"]: await act(action)
	await capture("01-legacy-completion-handoff")
	check(game.model.snapshot().chapter_complete,"legacy complete remains a valid stopping point")
	await act("begin_fair")
	await capture("02-fair-arrival-camera-callback")
	game.dispatch("dismiss")
	await capture("03-fair-courtyard")
	check(game.world_container.get_child(0).get_node_or_null("Mira") != null,"authored Mira rig retained in fair")
	await act("fair_greeting","ducks")
	await capture("04-duck-greeting")
	await act("fair_continue","fair_setup")
	for scale in [1.0,2.0]:
		var settings = game.model.snapshot().settings
		settings.text_scale = scale
		game.change_settings(settings)
		game.show_fair_state()
		await settle()
		for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()),"setup footer visible scale "+str(scale))
		await capture("05-setup-scale-"+str(scale))
		await act("fair_config","rudder")
		for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()),"rudder options visible scale "+str(scale))
		game.show_pause()
		game.hud.resume_pause()
		await settle()
		check(game.hud.content.get_child(0).text == "Boats with opinions","pause restores boat configuration")
	var settings = game.model.snapshot().settings
	settings.text_scale = 1.0
	game.change_settings(settings)
	await act("set_rudder","left")
	await act("set_sail","folded")
	game.dispatch("release_boat")
	await create_timer(1.0).timeout
	await capture("06-crooked-race-moving")
	game.show_pause()
	await settle()
	check(game.hud.pause_active,"race can be paused")
	game.hud.resume_pause()
	while game.racing: await process_frame
	await capture("07-all-at-the-duck")
	await act("inspect_fair","together")
	await capture("08-check-wedge-together")
	await act("fair_continue","fair_level")
	await act("level_pond","ada")
	await capture("09-level-pond")
	await act("set_rudder","straight")
	await act("set_sail","triangle")
	game.dispatch("release_boat")
	await create_timer(1.0).timeout
	await capture("10-levelled-race-moving")
	while game.racing: await process_frame
	await capture("11-authored-race-outcome")
	var canonical = game.model.snapshot()
	await act("replay_race")
	check(game.model.snapshot().fair.outcome == canonical.fair.outcome,"replay preserves canonical past outcome")
	check(game.model.snapshot().choice_history == canonical.choice_history,"replay does not reapply consequences")
	await act("fair_departure","speak")
	await capture("12-mira-autonomy-available-build-end")
	check(game.model.snapshot().fair_checkpoint == "complete","second chapter truly completes")
	var restored = game.store.load_snapshot(game.save_path)
	check(restored.ok and restored.data.fair_checkpoint == "complete","second chapter reload persists")
	check(restored.data.camera_choice == "lend","legacy camera choice preserved")

	var configurations = [["first","operate","straight","triangle","take"],["second","cooperate","left","folded","lend"],["third","operate","left","square","unused"],["circle","operate","straight","folded","take"],["spectator","watch","right","folded","unused"]]
	for config in configurations:
		game.model = load("res://core/chapter_model.gd").new()
		game.save_path = "user://fair_rendered_branch_"+config[0]+"_"+str(Time.get_ticks_usec())+".json"
		for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: game.model.apply(action)
		game.model.apply("choose_camera",config[4])
		game.model.apply("resolve_action","completed")
		for action in ["return_train","have_breakfast","finish","begin_fair"]: game.model.apply(action)
		game.hud.close_all()
		game.route()
		game.show_fair_state()
		await capture("13-camera-"+config[4]+"-"+config[0])
		game.model.apply("fair_greeting","how")
		game.model.apply("set_race_mode",config[1])
		game.model.apply("set_rudder",config[2])
		game.model.apply("set_sail",config[3])
		game.model.apply("release_boat")
		game.model.apply("inspect_fair","wedge")
		game.model.apply("level_pond","self")
		game.model.apply("release_boat")
		game.route()
		await act("replay_race")
		check(game.model.snapshot().fair.outcome == config[0],"rendered outcome "+config[0])
		check(game.model.snapshot().fair.souvenir_ids == ["fair_button"],"same persistent button "+config[0])
		var accessible = game.model.snapshot().settings
		accessible.text_scale = 2.0
		game.change_settings(accessible)
		game.show_fair_state()
		await settle()
		for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()),"outcome2x choice visible "+config[0])
		await capture("14-outcome-"+config[0]+"-scale2")

	var report = FileAccess.open(out+"/report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"scope":"actual graphical Godot runtime; scripted route and menu events, physical controller and human sound listening unverified"},"  "))
	print("Fair rendered QA: ",checks," checks; ",failures," failures")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
