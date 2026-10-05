extends SceneTree
var game
var failures := 0
var checks := 0
var out := "res://../evidence/kitchen/rendered"
func check(ok: bool, label: String):
	checks += 1
	print("QA ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func settle():
	await create_timer(0.12).timeout
	await process_frame
func capture(id: String):
	await settle()
	root.get_texture().get_image().save_png(out + "/" + id + ".png")
func act(action: String, value: Variant = null):
	game.dispatch(action,value)
	while game.kitchen_animating: await process_frame
	await settle()
func seed_paper() -> Dictionary:
	var model = load("res://core/chapter_model.gd").new()
	model.apply("settings", {"text_scale":1.0,"subtitles":true,"reduced_motion":true,"sensitivity":1.0,"master":0.0,"music":0.0,"effects":0.0,"graphics":"medium"})
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: model.apply(action)
	model.apply("choose_camera","lend")
	model.apply("resolve_action","skipped")
	for action in ["return_train","have_breakfast","finish","begin_fair"]: model.apply(action)
	for pair in [["fair_greeting","ducks"],["release_boat",null],["inspect_fair","together"],["level_pond","ada"],["release_boat",null],["fair_departure","card"],["begin_paper",null],["paper_greeting","begin"],["set_paper_star","crooked"],["set_paper_layout","boat_leaf_star"],["set_paper_length","long"],["set_paper_mode","direct"],["set_paper_fold","wider"],["raise_paper",null],["finish_paper",null]]: model.apply(pair[0],pair[1])
	return model.snapshot()
func reset(seed):
	check(game.model.restore(seed), "restore saved Chapter Three")
	game.hud.close_all()
	game.route()
func visible_choices(label_):
	for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()),label_+" visible choice "+b.text)
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://kitchen_rendered_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await settle()
	var seed = seed_paper()
	reset(seed)
	await act("begin_kitchen")
	await capture("01-arrival-place-set")
	game.dispatch("dismiss")
	await capture("02-warm-kitchen-wide")
	await act("kitchen_view")
	await capture("03-place-before-task-table")
	await act("kitchen_leave_view")
	for scale in [1.0,2.0]:
		var settings = game.model.snapshot().settings
		settings.text_scale = scale
		game.change_settings(settings)
		for id in ["kitchen_arrival","kitchen_supper","kitchen_bread","kitchen_cup","kitchen_pepper","kitchen_conversation","kitchen_complete","kitchen_sign","kitchen_camera"]:
			game.show_kitchen_state(id)
			await settle()
			visible_choices(id+" text "+str(scale))
			await capture("text-"+str(scale)+"-"+id)
			var before = game.hud.content.get_child(0).text
			game.show_pause()
			game.hud.resume_pause()
			await settle()
			check(game.hud.content.get_child(0).text == before,"pause restores "+id+" at "+str(scale))
	var routes := 0
	for mode in ["sit","help","watch"]:
		for exchange in ["bread","cup","pepper","watch"]:
			for departure in ["ask","wish","listen"]:
				reset(seed)
				await act("begin_kitchen")
				await act("kitchen_join",mode)
				check(game.model.snapshot().kitchen.served,"served "+mode+exchange+departure)
				await act("kitchen_share",exchange)
				check(game.model.snapshot().kitchen_checkpoint == "conversation","conversation "+mode+exchange+departure)
				await act("kitchen_departure",departure)
				check(game.model.snapshot().kitchen.completed,"complete "+mode+exchange+departure)
				var complete = game.model.snapshot()
				check(game.store.load_snapshot(game.save_path).data.kitchen == complete.kitchen,"exact saved dinner "+str(routes))
				game.route()
				check(game.model.snapshot().paper == seed.paper and game.model.snapshot().npc_state == seed.npc_state,"callbacks and autonomy survive "+str(routes))
				if departure == "listen" and exchange == "watch":
					await act("kitchen_view")
					await capture("complete-table-"+mode)
					await act("kitchen_leave_view")
				routes += 1
	# Actual timed staging, with pause and a live accessibility toggle.
	reset(seed)
	await act("begin_kitchen")
	var settings = game.model.snapshot().settings
	settings.reduced_motion = false
	settings.text_scale = 1.0
	game.change_settings(settings)
	game.dispatch("kitchen_join","help")
	await create_timer(1.3).timeout
	await capture("04-ladle-and-conversation-live")
	game.show_pause()
	var kitchen = game.world_container.get_child(0)
	var elapsed = kitchen.gesture_elapsed
	await create_timer(0.4).timeout
	check(kitchen.gesture_elapsed == elapsed,"pause freezes rendered ladle gesture")
	await capture("05-pause-during-dinner")
	game.hud.resume_pause()
	while game.kitchen_animating: await process_frame
	await settle()
	game.dispatch("kitchen_share","bread")
	await create_timer(1.3).timeout
	await capture("06-bread-tearing-and-passing-live")
	settings.reduced_motion = true
	game.change_settings(settings)
	await settle()
	check(not game.kitchen_animating and game.model.snapshot().kitchen_checkpoint == "conversation","live reduced-motion toggle keeps exchange functional")
	await act("kitchen_departure","ask")
	await act("kitchen_sign_view")
	await capture("07-exact-sign-callback")
	game.show_pause()
	game.hud.resume_pause()
	check(game.kitchen_viewing,"pause retains physical sign view")
	await act("kitchen_leave_view")
	check(game.player.enabled,"leaving sign view restores exploration")
	# Normal-motion sit and watching serving differ but remain complete.
	for mode in ["sit","watch"]:
		reset(seed)
		await act("begin_kitchen")
		settings = game.model.snapshot().settings
		settings.reduced_motion = false
		game.change_settings(settings)
		game.dispatch("kitchen_join",mode)
		await create_timer(1.25).timeout
		await capture("gesture-serving-"+mode)
		while game.kitchen_animating: await process_frame
		await act("kitchen_share","watch")
		await act("kitchen_departure","listen")
		check(game.model.snapshot().kitchen.completed,"animated "+mode+" route completes equally")
	var report = {"checks":checks,"failures":failures,"routes":routes,"renderer":RenderingServer.get_video_adapter_name(),"display":DisplayServer.get_name(),"limits":"Cloud graphical scripted QA; hearing, hardware GPU, physical controllers and mobile unverified"}
	var file = FileAccess.open(out+"/report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print(JSON.stringify(report))
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	game = null
	call_deferred("quit",1 if failures else 0)
