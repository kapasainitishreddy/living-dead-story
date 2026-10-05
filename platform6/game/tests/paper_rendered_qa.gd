extends SceneTree
var game
var failures := 0
var checks := 0
var out := "res://../evidence/paper/rendered"
func check(ok: bool, label: String):
	checks += 1
	print("QA ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func settle():
	await create_timer(0.15).timeout
	await process_frame
func capture(id: String):
	await settle()
	root.get_texture().get_image().save_png(out + "/" + id + ".png")
func act(action: String, value: Variant = null):
	game.dispatch(action, value)
	while game.racing: await process_frame
	await settle()
func seed_fair():
	game.model = load("res://core/chapter_model.gd").new()
	game.model.apply("settings", {"text_scale":1.0,"subtitles":true,"reduced_motion":true,"sensitivity":1.0,"master":0.0,"music":0.0,"effects":0.0,"graphics":"medium"})
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: check(game.model.apply(action), "seed " + action)
	game.model.apply("choose_camera", "lend")
	game.model.apply("resolve_action", "skipped")
	for action in ["return_train","have_breakfast","finish","begin_fair"]: game.model.apply(action)
	game.model.apply("fair_greeting", "ducks")
	game.model.apply("release_boat")
	game.model.apply("inspect_fair", "together")
	game.model.apply("level_pond", "ada")
	game.model.apply("release_boat")
	game.model.apply("fair_departure", "card")
	game.paper_courtyard = false
	game.hud.close_all()
	game.route()
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://paper_rendered_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await settle()
	seed_fair()
	await act("begin_paper")
	await capture("01-arrival-noor-rafi")
	await act("paper_greeting", "begin")
	game.dispatch("dismiss")
	await capture("02-warm-conservatory")
	for scale in [1.0, 2.0]:
		var settings = game.model.snapshot().settings
		settings.text_scale = scale
		game.change_settings(settings)
		for page in ["main","star","layout","layout_other","length","fold","watch"]:
			await act("paper_config", page)
			for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()), page + " footer visible at " + str(scale))
			await capture("03-" + page + "-text-" + str(scale))
			game.show_pause()
			game.hud.resume_pause()
			await settle()
			check(game.hud.content.get_child(0).text == "The hanging rail", "pause restores " + page)
	var route := 0
	for star in ["crooked","clean","empty"]:
		for layout in ["leaf_boat_star","boat_star_leaf","star_leaf_boat","leaf_star_boat","boat_leaf_star","star_boat_leaf"]:
			for mode in ["assemble","direct","watch"]:
				seed_fair()
				await act("begin_paper")
				await act("paper_greeting", "begin")
				await act("set_paper_star", star)
				await act("set_paper_layout", layout)
				await act("set_paper_mode", mode)
				await act("set_paper_length", ["short","medium","long"][route % 3])
				await act("set_paper_fold", ["keep","wider","enough"][route % 3])
				var configured = game.model.snapshot()
				game.route()
				check(game.model.snapshot().paper == configured.paper, "interrupt keeps " + star + layout + mode)
				await act("raise_paper")
				check(game.model.snapshot().paper_checkpoint == "raised", "raised " + star + layout + mode)
				game.dispatch("dismiss")
				await capture("sign-" + star + "-" + layout + "-" + mode)
				await act("finish_paper")
				check(game.model.snapshot().paper_checkpoint == "complete", "complete " + star + layout + mode)
				await act("paper_courtyard")
				check(game.world_container.get_child(0).get_node_or_null("MountedPaperSign") != null, "physical courtyard revisit " + star + layout + mode)
				if layout == "leaf_boat_star" and mode == "assemble": await capture("mounted-" + star)
				await act("paper_inspect")
				check(game.hud.content.get_child(1).text.contains(star + " star"), "exact description on revisit " + star)
				check(game.store.load_snapshot(game.save_path).data.paper == game.model.snapshot().paper, "exact object save reload " + str(route))
				route += 1
	var report = {"checks":checks,"failures":failures,"routes":route,"renderer":RenderingServer.get_video_adapter_name(),"display":DisplayServer.get_name(),"limits":"Cloud graphical scripted QA; hardware audio, physical controllers, mobile and target GPU unverified"}
	var file = FileAccess.open(out + "/report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	game = null
	call_deferred("quit", 1 if failures else 0)
