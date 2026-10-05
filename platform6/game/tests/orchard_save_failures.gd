extends SceneTree
const Probe = preload("res://tests/kitchen_quit_probe.gd")
var failures := 0
var checks := 0
func check(ok: bool,label: String):
	checks += 1
	print("PASS " if ok else "FAIL ",label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var game = Probe.new()
	game.save_path = "user://orchard_failure_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("request_quit"),"all orchard exit paths share durable save guard")
	if game.has_method("request_quit"):
		var helper = load("res://tests/orchard_runtime.gd").new()
		check(game.model.restore(helper.kitchen_seed()),"restore kitchen seed")
		helper.free()
		game.route()
		game.dispatch("begin_orchard")
		var file = FileAccess.open(game.save_path,FileAccess.WRITE)
		file.store_string(JSON.stringify({"schema_version":game.Model.SCHEMA_VERSION+1}))
		file.close()
		game.dispatch("orchard_route","bench")
		game.dispatch("orchard_advance")
		check(game.hud.notice.text.contains("Unsaved"),"failed manual beat warning")
		var before = game.model.snapshot()
		game.dispatch("orchard_view")
		check(game.hud.notice.text.contains("Unsaved"),"warning survives observation")
		game.dispatch("orchard_leave_view")
		game.show_pause()
		game.hud.quit_requested.emit()
		check(game.attempted_exits == 0,"pause quit blocks failed save")
		game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
		check(game.attempted_exits == 0,"OS close blocks failed save")
		game.hud.resume_pause()
		game.dispatch("orchard_leave")
		check(game.attempted_exits == 0,"save-and-leave blocks failed save")
		check(game.model.snapshot() == before,"failed exits preserve in-memory choice")
		DirAccess.remove_absolute(game.save_path)
		game.request_quit()
		check(game.attempted_exits == 1,"successful retry exits once")
		check(game.store.load_snapshot(game.save_path).data == before,"successful retry persists exact state")
	game.queue_free()
	await process_frame
	print("ORCHARD SAVE FAILURE ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
