extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://enrich_regression_"+str(Time.get_ticks_usec())+".json"
	root.add_child(game)
	await process_frame
	var invalid_marker = Marker3D.new()
	invalid_marker.set_meta("action_id","dialogue")
	invalid_marker.set_meta("value","train_window")
	game.on_interact(invalid_marker)
	check(not game.hud.modal_visible() and game.player.enabled,"interaction cannot open wrong-checkpoint local branch")
	invalid_marker.free()
	game.hud.close_all()
	game.resume_controls()
	game.hud.show_dialogue("meet_passenger")
	game.show_pause()
	var prefs = game.model.snapshot().settings
	prefs.text_scale = 2.0
	game.change_settings(prefs)
	game.hud.resume_pause()
	check(game.hud.content.get_child(1).get_theme_font_size("font_size") == 46,"paused dialogue refreshes text scale on resume")
	check(game.hud.footer.get_child(0).get_theme_font_size("font_size") == 38,"paused choice refreshes text scale on resume")
	game.hud.close_all()
	game.player.set_framed_view(false)
	await create_timer(0.5).timeout
	game.player.pivot.rotation.y = 0.9
	game.player.set_framed_view(true)
	await create_timer(0.05).timeout
	prefs.reduced_motion = true
	game.player.set_preferences(prefs)
	var yaw = game.player.pivot.rotation.y
	await create_timer(0.25).timeout
	check(is_equal_approx(game.player.pivot.rotation.y,yaw),"enabling reduced motion cancels existing automatic camera movement")
	game.audio.crossfade_location("platform")
	await create_timer(0.05).timeout
	game.audio.crossfade_location("passenger")
	await create_timer(1.65).timeout
	check(is_equal_approx(game.audio.gains[game.audio.active_slot],0.62),"same-stream location switch updates in-flight fade endpoint")
	prefs.master = 0.0
	game.audio.apply_settings(prefs)
	check(game.audio.effects.volume_db <= -80 and game.audio.effects_secondary.volume_db <= -80,"both ambience layers muted")
	game.hud.close_all()
	game.model = load("res://core/chapter_model.gd").new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore"]: game.model.apply(action)
	game.route()
	var marker
	for node in game.world_container.get_child(0).get_children():
		if node.get_meta("value","") == "lighthouse": marker = node
	game.on_interact(marker)
	game.dispatch("dismiss")
	game.on_interact(marker)
	check(game.hud.modal_visible() and game.hud.content.get_child(0).text == "Two lights","landmark discovery can be reread after Back")
	game.hud.show_pause(prefs)
	game.hud.resume_pause()
	game.hud.close_all()
	await process_frame
	await process_frame
	game.queue_free()
	await process_frame
	print("Enrichment regression checks: %d; failures: %d" % [checks,failures])
	quit(1 if failures else 0)
