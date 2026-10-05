extends SceneTree
# Exercise authored scene markers rather than bypassing them with direct dispatch.
var game
var checks := 0
var failures := 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _initialize(): call_deferred("run")
func target(action: String) -> Node:
	for item in get_nodes_in_group("interactables"):
		if game.world_container.is_ancestor_of(item) and item.get_meta("action_id", "") == action: return item
	return null
func interact(action: String):
	var item = target(action)
	check(item != null, "actual scene exposes " + action)
	if item != null: game.on_interact(item)
func cancel():
	var event = InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	game._unhandled_input(event)
func return_seed(camera := "lend") -> Dictionary:
	var helper = load("res://tests/return_runtime.gd").new()
	var value = helper.orchard_seed(camera)
	helper.free()
	return value
func start(value: Dictionary):
	check(game.model.restore(value), "restore exact source state")
	game.hud.close_all()
	game.route()
func run():
	game = load("res://main.tscn").instantiate()
	game.save_path = "user://return_reachability_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	for camera in ["take", "lend", "unused"]:
		for presentation in ["normal", "skip", "reduced"]:
			start(return_seed(camera))
			var settings = game.model.snapshot().settings
			settings.reduced_motion = presentation == "reduced"
			game.change_settings(settings)
			game.dispatch("begin_return")
			game.dispatch("dismiss")
			var world = game.world_container.get_child(0)
			world.set_process(false)
			interact("return_arrival")
			if presentation == "normal": world._process(world.PREPARATION_DURATION)
			elif presentation == "skip": cancel()
			check(not game.return_cinematic and game.hud.modal_visible(), "preparation restores farewell menu " + presentation + camera)
			check(world.snapshot.return_checkpoint == "farewell", "preparation keeps live world synchronized")
			game.dispatch("dismiss")
			interact("return_farewell")
			check(game.hud.modal_visible() and game.hud.footer.get_child_count() >= 5, "Mira marker reopens five choices")
			game.hud.footer.get_child(2).pressed.emit()
			check(game.model.snapshot().return_checkpoint == "departed", "farewell persists departure before presentation")
			if presentation == "normal":
				game.show_pause()
				var before = world.cinematic_state()
				world._process(60.0)
				check(world.cinematic_state() == before, "normal departure freezes during pause")
				game.hud.resume_pause()
				world._process(world.departure_duration())
			elif presentation == "skip": cancel()
			check(not game.return_cinematic and game.player.enabled and not game.hud.modal_visible(), "departure restores open platform " + presentation + camera)
			check(world.snapshot.return_checkpoint == "departed", "live world reaches durable departure")
			check(target("return_arrival") == null and target("return_farewell") == null, "departed scene removes obsolete Mira targets")
			for action in ["return_conductor", "return_jo"]:
				interact(action)
				check(game.hud.modal_visible(), "optional contact reachable " + action)
				game.dispatch("dismiss")
			interact("return_finish")
			check(game.model.snapshot().return_checkpoint == "complete", "scene completion target actually finishes")
			check(target("return_exit") != null, "completion exposes live exit marker")
	# The accepted-but-not-departed save can arise if the second save is interrupted.
	var selected = load("res://core/chapter_model.gd").new()
	selected.restore(return_seed())
	for step in [["begin_return",null],["return_arrival",null],["return_farewell","wave"]]: selected.apply(step[0],step[1])
	start(selected.snapshot())
	interact("return_farewell")
	check(game.hud.content.get_child(0).text == "A goodbye to keep", "selected reload never offers replacement farewells")
	game.hud.footer.get_child(0).pressed.emit()
	check(game.model.snapshot().return_checkpoint == "departed" and game.model.snapshot().return_state.farewell == "wave", "selected reload departs with original goodbye")
	# Optional station people remain useful if completion happened before either visit.
	selected.apply("return_departure")
	selected.apply("return_finish")
	start(selected.snapshot())
	for action in ["return_jo", "return_conductor"]:
		interact(action)
		var field = "jo_met" if action == "return_jo" else "conductor_revealed"
		check(game.hud.modal_visible() and game.model.snapshot().return_state[field], "completed first visit actually responds " + action)
		game.dispatch("dismiss")
	check(game.store.load_snapshot(game.save_path).data == game.model.snapshot(), "completed optional visits save exact history")
	# Chapter One's similarly prefixed return_train remains its original adapter.
	var legacy = load("res://core/chapter_model.gd").new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: legacy.apply(action)
	legacy.apply("choose_camera", "unused")
	legacy.apply("resolve_action", "skipped")
	start(legacy.snapshot())
	interact("return_train")
	check(game.hud.modal_visible() and game.hud.content.get_child(0).text == game.hud.authored.dialogues.return_train.title, "Chapter One return_train opens original dialogue")
	game.hud.footer.get_child(0).pressed.emit()
	check(game.model.snapshot().campaign_chapter == "platform_six" and game.model.snapshot().checkpoint_id == "breakfast", "Chapter One return_train button preserves legacy transition")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	print("RETURN REACHABILITY ", checks, " checks ", failures, " failures")
	quit(1 if failures else 0)
