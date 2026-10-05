extends SceneTree
var checks := 0
var failures := 0
const Model = preload("res://core/chapter_model.gd")
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func overlook_model():
	var model = Model.new()
	for action in ["leave_apartment", "meet_stranger", "read_board", "board_train", "meet_passenger", "arrive_shore"]: model.apply(action)
	return model
func run():
	root.size = Vector2i(1280, 720)
	var model = overlook_model()
	for value in [-1, 3, 1.5, "2", null]:
		var before = model.snapshot()
		check(not model.apply("preview_alignment", value) and model.snapshot() == before, "invalid preview is atomic: " + str(value))
	check(model.apply("preview_alignment", 2) and not model.snapshot().puzzle_solved, "uninspected whole-shore preview remains unsolved")
	check(model.apply("align", 2) and model.snapshot().checkpoint_id == "overlook", "Keep cannot silently replace missing discoveries")
	for landmark in ["constellation", "lighthouse", "arch"]: model.apply("inspect_landmark", landmark)
	check(model.apply("preview_alignment", 0) and model.apply("align", 0) and not model.snapshot().puzzle_solved, "wrong framing stays reversible after all discoveries")
	var restore = Model.new()
	check(restore.restore(model.snapshot()) and restore.snapshot().overlook_alignment == 0, "saved reversible framing reloads exactly")
	for choice in ["take", "lend", "unused"]:
		var outcomes = []
		for resolution in ["completed", "skipped"]:
			var branch = overlook_model()
			check(branch.apply("assist"), "Assist stays immediately available for " + choice)
			branch.apply("choose_camera", choice)
			branch.apply("resolve_action", resolution)
			branch.apply("return_train")
			branch.apply("have_breakfast")
			branch.apply("finish")
			var state = branch.snapshot()
			state.erase("action_resolution")
			outcomes.append(state)
		check(outcomes[0] == outcomes[1], "Done / Not tonight retain exact durable parity for " + choice)
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_regression_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	game.model = restore
	game.route()
	var puzzle
	for target in game.world_container.get_child(0).get_children():
		if target.get_meta("action_id", "") == "puzzle": puzzle = target
	game.on_interact(puzzle)
	var camera = game.opening_story.framing_camera
	check(camera.current and game.hud.modal_visible() and not game.player.enabled, "reloaded preview uses the camera with walking gated")
	game.dispatch("preview_alignment", 1)
	var view = camera.global_transform
	game.show_pause()
	check(camera.current and game.opening_story.paused, "pause holds the actual framing view")
	game.hud.resume_pause()
	check(camera.current and camera.global_transform == view and not game.player.enabled, "resume preserves preview and dialogue gating")
	game.dispatch("dismiss")
	check(not camera.current and game.player.enabled, "Back after pause restores player exploration")
	var saved = game.store.load_snapshot(game.save_path)
	check(saved.ok and saved.data.overlook_alignment == 1 and not saved.data.puzzle_solved, "preview is durable before solving")
	game.model.restore(saved.data)
	game.route()
	check(not game.opening_story.framing_camera.current, "reopening a saved preview never traps the player in camera mode")
	game.queue_free(); await process_frame
	print("Opening story regressions: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
