extends SceneTree
const Probe = preload("res://tests/kitchen_quit_probe.gd")
var failures := 0
var checks := 0
func check(ok: bool,label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var game = Probe.new()
	game.save_path = "user://home_failure_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("dispatch_home"), "home durability adapter exists")
	if game.has_method("dispatch_home") and game.model.has_method("apply_home"):
		await verify_failures(game)
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("HOME SAVE FAILURE ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
func verify_failures(game):
	var helper = load("res://tests/home_runtime.gd").new()
	check(game.model.restore(helper.completed_return("lend")), "restore complete prior journey")
	helper.free()
	game.route()
	game.dispatch("begin_home")
	var file = FileAccess.open(game.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":game.Model.SCHEMA_VERSION+1}))
	file.close()
	game.dispatch("home_ticket", "drawer")
	check(game.hud.notice.text.contains("Unsaved"), "failed ticket save stays visible")
	game.dispatch("home_ritual", "window")
	game.dispatch("home_end", "sleep")
	await process_frame
	check(game.hud.notice.text.contains("Unsaved"), "failed ending save stays visible after physical hold and credits")
	var before = game.model.snapshot()
	game.dispatch("home_state")
	check(game.hud.notice.text.contains("Unsaved"), "warning survives revisiting credits")
	game.dispatch("home_view")
	check(game.hud.notice.text.contains("Unsaved"), "warning survives stable home view")
	game.dispatch("home_leave_view")
	check(game.hud.notice.text.contains("Unsaved"), "warning survives leaving view")
	game.show_pause()
	game.hud.quit_requested.emit()
	check(game.attempted_exits == 0, "pause quit blocks failed save")
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(game.attempted_exits == 0, "OS close blocks failed save")
	game.hud.resume_pause()
	game.dispatch("home_leave")
	check(game.attempted_exits == 0, "save-and-leave blocks failed save")
	check(game.model.snapshot() == before, "failed exits preserve exact in-memory home branch")
	DirAccess.remove_absolute(game.save_path)
	game.request_quit()
	check(game.attempted_exits == 1, "successful retry exits once")
	check(game.store.load_snapshot(game.save_path).data == before, "successful retry writes exact completed campaign")
	check(not game.hud.notice.text.contains("Unsaved"), "successful retry clears save warning")
