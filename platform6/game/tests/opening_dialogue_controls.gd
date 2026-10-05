extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func key(code: int, pressed: bool):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
func run():
	root.size = Vector2i(1280, 720)
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://opening_controls_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	game.hud.show_dialogue("leave_apartment", game.model.snapshot())
	game.player.set_controls_enabled(false)
	for i in 3: await process_frame
	check(get_root().gui_get_focus_owner() == game.hud.footer.get_child(0), "authored first choice owns keyboard focus")
	check(game.hud.modal.get_global_rect().position.y >= 340, "short opening dialogue sits below the speaker")
	key(KEY_ENTER, true)
	await process_frame
	key(KEY_ENTER, false)
	await process_frame
	check(game.model.snapshot().checkpoint_id == "roof", "a focused physical Enter press activates the first door choice")
	game.hud.close_all(); game.resume_controls()
	game.hud.show_dialogue("meet_stranger", game.model.snapshot())
	game.player.set_controls_enabled(false)
	for i in 3: await process_frame
	key(KEY_ENTER, true); await process_frame; key(KEY_ENTER, false); await process_frame
	check("platform_six.dialogue.umbrella_question" in game.model.snapshot().choice_history, "focused Enter opens and records a branch once")
	var prefs = game.model.snapshot().settings
	prefs.text_scale = 2.0
	game.change_settings(prefs)
	game.hud.show_dialogue("meet_passenger")
	for i in 4: await process_frame
	var viewport = Rect2(Vector2.ZERO, Vector2(1280, 720))
	for button in game.hud.footer.get_children(): check(viewport.encloses(button.get_global_rect()), "2x opening choice remains reachable: " + button.text)
	game.hud.show_puzzle(game.model.snapshot())
	for i in 4: await process_frame
	check(game.hud.modal.get_global_rect().position.x > 620, "framing choices leave the actual shore view exposed")
	for button in game.hud.footer.get_children(): check(viewport.encloses(button.get_global_rect()), "2x framing choice remains reachable: " + button.text)
	game.show_pause()
	game.hud.resume_pause()
	for i in 3: await process_frame
	check(game.hud.modal.get_global_rect().position.x > 620, "pause resumes the same shore-side layout")
	game.queue_free(); await process_frame
	print("Opening dialogue controls: %d checks; %d failures" % [checks, failures])
	quit(1 if failures else 0)
