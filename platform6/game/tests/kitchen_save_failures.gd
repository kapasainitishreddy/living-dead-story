extends SceneTree
const Model = preload("res://core/chapter_model.gd")
const QuitProbe = preload("res://tests/kitchen_quit_probe.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func completed_paper() -> Dictionary:
	var model = Model.new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]:
		check(model.apply(action), "seed " + action)
	check(model.apply("choose_camera","unused"), "seed unopened camera")
	check(model.apply("resolve_action","skipped"), "seed private optional response")
	for action in ["return_train","have_breakfast","finish","begin_fair"]:
		check(model.apply(action), "seed " + action)
	for step in [["fair_greeting","watch"],["release_boat",null],["inspect_fair","watch"],["level_pond","ada"],["release_boat",null],["fair_departure","wait"],["begin_paper",null],["paper_greeting",null],["raise_paper",null],["finish_paper",null]]:
		check(model.apply(step[0],step[1]), "seed " + step[0])
	return model.snapshot()
func warning_visible(game) -> bool:
	return game.hud.notice.text.to_lower().contains("unsaved")
func settle_gesture(game):
	var kitchen = game.world_container.get_child(0)
	if kitchen.has_method("finish_gesture"): kitchen.finish_gesture()
	else: kitchen._process(8.0)
func run():
	var game = QuitProbe.new()
	game.save_path = "user://kitchen_save_failure_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.model.restore(completed_paper()), "restore completed paper")
	game.route()
	game.dispatch("begin_kitchen")
	check(game.model.snapshot().kitchen_checkpoint == "arrival", "begin kitchen before controlled failure")
	var future_bytes = JSON.stringify({"schema_version":Model.SCHEMA_VERSION + 1})
	var file = FileAccess.open(game.save_path,FileAccess.WRITE)
	check(file != null, "create test-owned future-schema save")
	if file == null:
		game.free()
		quit(1)
		return
	file.store_string(future_bytes)
	file.close()
	check(game.store.read_file(game.save_path).error == "future schema", "real save store recognizes controlled failure")
	game.dispatch("kitchen_join","sit")
	check(game.model.snapshot().kitchen_checkpoint == "supper", "failed save keeps accepted supper in memory")
	check(warning_visible(game), "failed join warning visible immediately")
	game.update_kitchen_caption(2.1)
	check(warning_visible(game), "failed join warning survives second gesture caption")
	settle_gesture(game)
	check(warning_visible(game), "failed join warning survives gesture completion")
	check(not game.kitchen_animating, "failed join does not strand presentation")
	game.show_pause()
	game.hud.resume_pause()
	check(warning_visible(game), "failed join warning survives pause and resume")
	game.dispatch("kitchen_view")
	check(warning_visible(game), "failed save warning survives optional table view")
	game.dispatch("kitchen_leave_view")
	check(warning_visible(game), "failed save warning survives return to room")
	game.dispatch("kitchen_share","watch")
	check(game.model.snapshot().kitchen_checkpoint == "conversation", "failed save keeps accepted exchange in memory")
	check(warning_visible(game), "failed exchange warning visible immediately")
	game.update_kitchen_caption(2.1)
	check(warning_visible(game), "failed exchange warning survives second gesture caption")
	settle_gesture(game)
	check(warning_visible(game), "failed exchange warning survives gesture completion")
	game.dispatch("kitchen_departure","listen")
	check(game.model.snapshot().kitchen_checkpoint == "complete", "completion stays in memory after failed save")
	check(warning_visible(game), "failed completion warning remains visible")
	var completed = game.model.snapshot()
	game.dispatch("kitchen_leave")
	check(game.attempted_exits == 0, "failed Save and leave stays open for retry")
	check(game.model.snapshot() == completed, "failed Save and leave preserves exact unsaved journey")
	check(warning_visible(game), "failed Save and leave provides actionable warning")
	check(FileAccess.get_file_as_string(game.save_path) == future_bytes, "all failed writes retain future-schema source")
	check(DirAccess.remove_absolute(game.save_path) == OK, "remove only test-owned failure fixture")
	game.change_settings(game.model.snapshot().settings)
	check(not warning_visible(game), "successful settings retry clears stale unsaved warning")
	game.dispatch("kitchen_leave")
	check(game.attempted_exits == 1, "successful Save and leave requests exactly one exit")
	var saved = game.store.load_snapshot(game.save_path)
	check(saved.ok and saved.data == completed, "successful retry saves exact completed journey before exit")
	var test_path: String = game.save_path
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(test_path + suffix): DirAccess.remove_absolute(test_path + suffix)
	print("KITCHEN SAVE FAILURE ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
