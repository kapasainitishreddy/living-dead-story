extends SceneTree
# Real write failures in the original four chapters must not lose accepted choices.
const Model = preload("res://core/chapter_model.gd")
const Probe = preload("res://tests/kitchen_quit_probe.gd")
const CHAPTERS = ["platform_six", "the_small_fair", "paper_sky", "night_kitchen"]
var game
var checks := 0
var failures := 0

func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize(): call_deferred("run")

func fixture_snapshot(chapter: String) -> Dictionary:
	var m = Model.new()
	for action in ["leave_apartment", "meet_stranger", "read_board", "board_train", "meet_passenger", "arrive_shore", "assist"]:
		check(m.apply(action), "fixture " + action)
	if chapter != "platform_six":
		for item in [["choose_camera", "unused"], ["resolve_action", "skipped"], ["return_train", null], ["have_breakfast", null], ["finish", null], ["begin_fair", null], ["fair_greeting", "watch"]]:
			check(m.apply(item[0], item[1]), "fixture " + item[0])
	if chapter in ["paper_sky", "night_kitchen"]:
		for item in [["release_boat", null], ["inspect_fair", "watch"], ["level_pond", "ada"], ["release_boat", null], ["fair_departure", "wait"], ["begin_paper", null], ["paper_greeting", null]]:
			check(m.apply(item[0], item[1]), "fixture " + item[0])
	if chapter == "night_kitchen":
		for action in ["raise_paper", "finish_paper", "begin_kitchen"]:
			check(m.apply(action), "fixture " + action)
	var settings = m.snapshot().settings
	settings.reduced_motion = true
	check(m.apply("settings", settings), "fixture reduced motion")
	return m.snapshot()

func accepted_choice(chapter: String):
	var action = {"platform_six":["choose_camera", "lend"], "the_small_fair":["set_rudder", "right"], "paper_sky":["set_paper_star", "empty"], "night_kitchen":["kitchen_join", "watch"]}[chapter]
	var prior = game.model.snapshot()
	game.dispatch(action[0], action[1])
	for i in 3: await process_frame
	check(game.model.snapshot() != prior, "runtime accepts choice " + chapter)

func warning_visible() -> bool:
	return game.hud.notice.text.to_lower().contains("unsaved")

func start(chapter: String, path: String):
	game.save_path = path
	check(game.model.restore(fixture_snapshot(chapter)), "restore " + chapter)
	game.hud.close_all()
	game.route()
	check(game.persist(), "initial clean fixture writes " + chapter)

func verify_failure(chapter: String, future: bool):
	var good_path = "user://campaign_exit_" + chapter + "_" + str(Time.get_ticks_usec()) + ".json"
	start(chapter, good_path)
	var protected_bytes := ""
	if future:
		var fixture = game.model.snapshot()
		fixture.schema_version = Model.SCHEMA_VERSION + 1
		protected_bytes = JSON.stringify(fixture)
		var file = FileAccess.open(good_path, FileAccess.WRITE)
		file.store_string(protected_bytes)
		file.close()
	else:
		game.save_path = "/proc/platform6_campaign_save_failure/save.json"
	await accepted_choice(chapter)
	var label = chapter + (" future" if future else " unwritable")
	check(warning_visible(), "warning survives accepted choice " + label)
	if chapter == "platform_six":
		check(game.hud.notice.text.contains("Mira"), "camera reply remains alongside warning " + label)
	elif chapter == "the_small_fair":
		game.dispatch("release_boat")
		while game.racing: await process_frame
		check(warning_visible(), "warning survives pond presentation " + label)
	elif chapter == "paper_sky":
		game.dispatch("paper_close_view")
		check(warning_visible(), "warning survives paper view " + label)
		game.dispatch("paper_leave_view")
		check(warning_visible(), "warning survives paper view exit " + label)
	var exact = game.model.snapshot()
	var exits: int = game.attempted_exits
	game.show_pause()
	game.hud.quit_requested.emit()
	check(game.attempted_exits == exits and warning_visible(), "pause Quit guards failed write " + label)
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(game.attempted_exits == exits and warning_visible(), "OS close guards failed write " + label)
	game.hud.resume_pause()
	if chapter == "night_kitchen": game.dispatch("kitchen_leave")
	else: game.hud.quit_requested.emit()
	check(game.attempted_exits == exits and warning_visible(), "Save and leave guards failed write " + label)
	check(game.model.snapshot() == exact, "failed exits retain exact accepted choice " + label)
	if future:
		check(FileAccess.get_file_as_string(good_path) == protected_bytes, "future primary bytes retained " + label)
		check(DirAccess.remove_absolute(good_path) == OK, "remove only test-owned future fixture")
	game.save_path = good_path
	game.request_quit()
	check(game.attempted_exits == exits + 1, "successful retry exits exactly once " + label)
	check(game.store.load_snapshot(good_path).data == exact, "successful retry persists exact choice " + label)
	check(not warning_visible(), "successful retry clears stale warning " + label)

func verify_clean_and_damaged(chapter: String, damaged: bool):
	var path = "user://campaign_clean_exit_" + chapter + "_" + str(Time.get_ticks_usec()) + ".json"
	start(chapter, path)
	if damaged:
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string("{damaged test-owned source")
		file.close()
	var label = chapter + (" damaged" if damaged else " clean")
	await accepted_choice(chapter)
	check(not warning_visible(), "successful write stays clean " + label)
	if damaged:
		var retained := false
		var absolute = ProjectSettings.globalize_path(path)
		for filename in DirAccess.get_files_at(absolute.get_base_dir()):
			if filename.begins_with(absolute.get_file() + ".damaged."):
				retained = retained or FileAccess.get_file_as_string(absolute.get_base_dir().path_join(filename)) == "{damaged test-owned source"
		check(retained, "damaged source preserved without blocking repair " + label)
	var exact = game.model.snapshot()
	var exits: int = game.attempted_exits
	game.request_quit()
	check(game.attempted_exits == exits + 1, "clean Quit exits exactly once " + label)
	check(game.store.load_snapshot(path).data == exact, "clean Quit preserves exact choice " + label)

func run():
	game = Probe.new()
	game.save_path = "user://campaign_initial_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	for chapter in CHAPTERS:
		await verify_failure(chapter, false)
		await verify_failure(chapter, true)
		await verify_clean_and_damaged(chapter, false)
		await verify_clean_and_damaged(chapter, true)
	game.audio.shutdown()
	game.queue_free()
	await process_frame
	await process_frame
	print("CAMPAIGN SAVE FAILURE ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
