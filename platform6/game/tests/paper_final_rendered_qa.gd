extends "res://tests/paper_rendered_qa.gd"
func run():
	if DisplayServer.get_name() == "headless": quit(2); return
	out = ProjectSettings.globalize_path("res://../evidence/paper/final-rendered")
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://paper_final_rendered_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await settle()
	var route := 0
	for mode in ["assemble", "direct", "watch"]:
		seed_fair()
		await act("begin_paper")
		await act("paper_greeting", "begin")
		await act("set_paper_star", ["crooked","clean","empty"][route])
		await act("set_paper_layout", ["leaf_star_boat","boat_leaf_star","star_boat_leaf"][route])
		await act("set_paper_length", ["short","medium","long"][route])
		await act("set_paper_mode", mode)
		await act("set_paper_fold", ["keep","wider","enough"][route])
		await act("paper_close_view")
		check(game.paper_viewing and not game.player.enabled, "fixed preview close view " + mode)
		await capture("preview-close-" + mode)
		game.show_pause()
		var back = InputEventAction.new()
		back.action = "ui_cancel"
		back.pressed = true
		game._unhandled_input(back)
		await settle()
		check(game.paper_viewing and not game.hud.pause_active, "close view pause resume " + mode)
		await act("paper_leave_view")
		await act("raise_paper")
		var settings = game.model.snapshot().settings
		settings.text_scale = 2.0
		game.change_settings(settings)
		game.show_paper_state()
		for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()), "raised 2x footer " + mode)
		await capture("raised-dialogue-2x-" + mode)
		await act("paper_close_view")
		await capture("raised-close-" + mode)
		await act("paper_leave_view")
		await act("paper_shadow_view")
		await capture("shadow-" + mode)
		await act("paper_leave_view")
		await act("finish_paper")
		await act("paper_courtyard")
		check(not game.world_container.get_child(0).get_node("Booth/BoothSign").visible, "provisional board replaced " + mode)
		check(game.audio.current_location == "the_small_fair", "actual courtyard audio " + mode)
		await act("paper_inspect")
		check(not game.hud.footer.get_children().any(func(b): return b.text.contains("shadow")), "no unavailable shadow option " + mode)
		for b in game.hud.footer.get_children(): check(root.get_visible_rect().encloses(b.get_global_rect()), "revisit 2x footer " + mode)
		await act("paper_close_view")
		await capture("mounted-close-" + mode)
		await act("paper_leave_view")
		var saved = game.store.load_snapshot(game.save_path)
		check(saved.ok and saved.data.paper == game.model.snapshot().paper, "saved exact physical sign " + mode)
		game.model.restore(saved.data)
		game.route()
		await act("paper_close_view")
		await capture("mounted-reloaded-" + mode)
		check(game.model.snapshot().paper_checkpoint == "complete", "revisit reload remains complete " + mode)
		route += 1
	var file = FileAccess.open(out + "/report.json", FileAccess.WRITE)
	var report = {"checks":checks,"failures":failures,"routes":route,"renderer":RenderingServer.get_video_adapter_name(),"display":DisplayServer.get_name(),"scope":"Final code graphical close views, 2x raised/revisit controls, pause, exact reload, courtyard mounting/audio"}
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	file = null
	print(JSON.stringify(report))
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	game = null
	call_deferred("quit", 1 if failures else 0)
