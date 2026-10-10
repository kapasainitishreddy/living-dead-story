extends SceneTree
func _initialize(): call_deferred("run")

func run():
	var game = load("res://tests/kitchen_quit_probe.gd").new()
	var path = "user://reset_warning_" + str(Time.get_ticks_usec()) + ".json"
	game.save_path = path
	root.add_child(game)
	await process_frame
	var checks := 0
	var failures := 0
	if not game.persist():
		failures += 1
		printerr("FAIL: initial reset fixture saves")
	else:
		checks += 1
	var previous_chapter = game.model.snapshot().campaign_chapter
	game.save_path = "/proc/platform6_reset_failure/save.json"
	if game.persist() or not game.hud.notice.text.contains("Unsaved"):
		failures += 1
		printerr("FAIL: simulated failed save shows warning")
	else:
		checks += 1
	game.save_path = path
	game.dispatch("reset")
	await process_frame
	var fresh = game.store.load_snapshot(path)
	for assertion in [
		[game.model.snapshot().checkpoint_id == "apartment", "reset starts at the apartment"],
		[game.model.snapshot().campaign_chapter == previous_chapter, "reset retains the campaign opening"],
		[fresh.ok and fresh.data.checkpoint_id == "apartment", "reset writes the fresh save"],
		[game.hud.notice.text.is_empty(), "successful reset clears the visible stale save warning"],
		[game.campaign_save_warning.is_empty(), "successful reset clears campaign warning state"],
		[game.kitchen_save_warning.is_empty() and game.orchard_save_warning.is_empty() and game.return_save_warning.is_empty() and game.home_save_warning.is_empty(), "successful reset clears chapter warning state"]
	]:
		checks += 1
		if not assertion[0]:
			failures += 1
			printerr("FAIL: " + assertion[1])
		else:
			print("PASS: " + assertion[1])
	game.audio.shutdown()
	game.queue_free()
	await process_frame
	print("RESET SAVE WARNING ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
