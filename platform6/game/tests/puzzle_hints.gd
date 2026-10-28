extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func run():
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://puzzle_hints_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	for action in ["leave_apartment", "meet_stranger", "read_board", "board_train", "meet_passenger", "arrive_shore"]:
		check(game.model.apply(action), "reach the authored shore puzzle through normal checkpoint transitions: " + action)
	game.route()
	await process_frame
	var before = game.model.snapshot()
	game.hud.show_puzzle(before)
	await process_frame
	var button: Button = null
	for candidate in game.hud.footer.get_children():
		if candidate is Button and candidate.text == "Show a hint": button = candidate
	var hint = game.hud.content.find_child("PuzzleHint", true, false)
	check(button != null and hint != null and not hint.visible, "optional hint starts concealed and has a visible control")
	if button != null: button.pressed.emit()
	check(hint != null and hint.visible and hint.text.contains("lighthouse left") and hint.text.contains("stars right"), "first hint translates landmark clues into screen positions")
	check(game.model.snapshot() == before, "opening a hint leaves deterministic story state unchanged")
	check(button != null and button.text == "Show the next hint", "a clearer hint is available without forcing disclosure")
	game.dispatch("preview_alignment", 1)
	hint = game.hud.content.find_child("PuzzleHint", true, false)
	button = null
	for candidate in game.hud.footer.get_children():
		if candidate is Button and candidate.text == "Show the next hint": button = candidate
	check(hint != null and hint.visible and hint.text.contains("lighthouse left"), "changing the camera framing retains the requested clue")
	before = game.model.snapshot()
	if button != null: button.pressed.emit()
	check(hint != null and hint.text.contains("Step back") and hint.text.contains("all three shapes fit"), "second hint supplies the accessible camera solution")
	check(game.model.snapshot() == before, "revealing the direct hint still does not mutate or reward story state")
	game.show_pause()
	game.hud.resume_pause()
	check(game.hud.content.find_child("PuzzleHint", true, false) == hint and hint.visible, "pause and resume preserve the chosen hint and puzzle context")
	var prefs = game.model.snapshot().settings
	prefs.text_scale = 2.0
	game.change_settings(prefs)
	game.hud.show_puzzle(game.model.snapshot())
	await process_frame
	button = null
	for candidate in game.hud.footer.get_children():
		if candidate is Button and candidate.text == "Show a hint": button = candidate
	if button != null: button.pressed.emit(); button.pressed.emit()
	hint = game.hud.content.find_child("PuzzleHint", true, false)
	check(hint != null and hint.visible and hint.get_theme_font_size("font_size") == 36, "revealed text uses the selected 2x size")
	var viewport = Rect2(Vector2.ZERO, Vector2(1280, 720))
	for control in game.hud.footer.get_children():
		check(viewport.encloses(control.get_global_rect()), "hint-enabled 2x choice remains inside viewport: " + control.text)
	game.hud.close_all()
	check(game.model.apply("assist") and game.model.snapshot().checkpoint_id == "camera_choice", "original direct assist remains available and deterministic")
	game.audio.shutdown()
	game.queue_free()
	await process_frame
	print("Puzzle hints: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
