extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://kitchen_runtime_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("dispatch_kitchen"), "Night Kitchen has a playable runtime adapter")
	check(game.hud.has_method("show_kitchen_dialogue"), "Night Kitchen has accessible authored staging controls")
	if game.has_method("dispatch_kitchen") and game.hud.has_method("show_kitchen_dialogue"):
		await verify_routes(game)
	game.queue_free()
	await process_frame
	print("KITCHEN RUNTIME ",checks," checks ",failures," failures")
	call_deferred("quit", 1 if failures else 0)
func seed_complete_paper(game):
	var model = game.Model.new()
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: check(model.apply(action), "seed " + action)
	check(model.apply("choose_camera", "unused"), "seed unopened camera")
	check(model.apply("resolve_action", "skipped"), "seed optional action skipped")
	for action in ["return_train","have_breakfast","finish","begin_fair"]: check(model.apply(action), "seed " + action)
	for pair in [["fair_greeting","watch"],["set_race_mode","watch"],["release_boat",null],["inspect_fair","watch"],["level_pond","ada"],["release_boat",null],["fair_departure","wait"],["begin_paper",null],["paper_greeting","begin"],["set_paper_star","empty"],["set_paper_layout","star_boat_leaf"],["set_paper_length","long"],["set_paper_mode","watch"],["set_paper_fold","enough"],["raise_paper",null],["finish_paper",null]]:
		check(model.apply(pair[0],pair[1]), "seed " + pair[0])
	return model.snapshot()
func step(game, action, value = null):
	game.dispatch(action,value)
	await process_frame
	while game.kitchen_animating: await process_frame
	await process_frame
func verify_routes(game):
	var seed = seed_complete_paper(game)
	var settings = seed.settings
	settings.reduced_motion = true
	settings.text_scale = 2.0
	seed.settings = settings
	for mode in ["sit", "help", "watch"]:
		check(game.model.restore(seed), "restore preserved sign " + mode)
		game.route()
		game.show_paper_state()
		check(game.hud.footer.get_children().any(func(b): return b.text.contains("Night Kitchen")), "paper completion has explicit supper continuation " + mode)
		await step(game,"begin_kitchen")
		check(game.model.snapshot().kitchen_checkpoint == "arrival", "explicit kitchen arrival " + mode)
		check(game.hud.content.get_child(1).text.contains("already drawn back") and game.hud.content.get_child(1).text.contains("unopened"), "arrival place and camera continuity " + mode)
		var before = game.model.snapshot()
		game.show_pause()
		game.hud.resume_pause()
		await process_frame
		check(game.hud.content.get_child(0).text == "The Night Kitchen", "pause restores arrival " + mode)
		var button_index = ["sit","help","watch"].find(mode)
		game.hud.footer.get_child(button_index).pressed.emit()
		await process_frame
		while game.kitchen_animating: await process_frame
		check(game.model.snapshot().kitchen_checkpoint == "supper" and game.model.snapshot().kitchen.served, "real arrival button serves " + mode)
		check(game.hud.content.get_child(0).text == "At the table", "gesture returns to dinner " + mode)
		check(not game.kitchen_viewing, "instant reduced motion releases framed view " + mode)
		game.hud.close_all()
		game.resume_controls()
		var target = Node3D.new()
		target.set_meta("action_id", "kitchen_bread")
		game.world_container.get_child(0).add_child(target)
		game.on_interact(target)
		check(game.hud.content.get_child(0).text == "The crust", "valueless dinner object safely opens " + mode)
		game.show_pause()
		game.hud.resume_pause()
		check(game.hud.content.get_child(0).text == "The crust", "pause retains physical exchange " + mode)
		await step(game,"kitchen_share","watch")
		check(game.model.snapshot().kitchen_checkpoint == "conversation", "watch reaches Mira conversation " + mode)
		check(game.hud.content.get_child(1).text.contains("early tram") and game.hud.content.get_child(1).text.contains("asked if I could use it"), "Mira independently selected workshop " + mode)
		await step(game,"kitchen_departure","listen")
		check(game.model.snapshot().kitchen_checkpoint == "complete", "equal complete route " + mode)
		var completed = game.model.snapshot()
		check(completed.paper == before.paper and completed.fair == before.fair and completed.npc_state == before.npc_state and completed.dimensions == before.dimensions, "supper changes no prior reward or autonomy " + mode)
		check(game.store.load_snapshot(game.save_path).data.kitchen == completed.kitchen, "exact dinner save " + mode)
		game.hud.close_all()
		game.route()
		await step(game,"kitchen_view")
		check(game.kitchen_viewing and not game.player.enabled, "optional fixed dinner view " + mode)
		check(not game.player.visual.visible, "dinner camera never intersects avatar " + mode)
		game.show_pause()
		check(game.world_container.get_child(0).paused, "pause freezes the whole optional dinner view " + mode)
		game.hud.resume_pause()
		check(not game.world_container.get_child(0).paused, "resume unfreezes the optional dinner view " + mode)
		check(game.kitchen_viewing and not game.player.enabled, "pause restores same dinner view " + mode)
		var back = InputEventAction.new()
		back.action = "ui_cancel"
		back.pressed = true
		game._unhandled_input(back)
		check(not game.kitchen_viewing and game.player.enabled, "back releases dinner view " + mode)
		check(game.player.visual.visible, "leaving dinner camera restores avatar " + mode)
		await step(game,"kitchen_sign")
		check(game.hud.content.get_child(1).text.contains("Empty star") and game.hud.content.get_child(1).text.contains("long strings"), "sign callback retains exact choices " + mode)
		await step(game,"kitchen_sign_view")
		check(game.kitchen_viewing, "saved sign remains inspectable " + mode)
		await step(game,"kitchen_leave_view")
		check(not game.model.apply("kitchen_join",mode), "repeat arrival cannot overwrite dinner " + mode)
	# Interrupted visible gestures must already have coherent durable checkpoints.
	check(game.model.restore(seed), "restore normal-motion fixture")
	game.route()
	await step(game,"begin_kitchen")
	settings = game.model.snapshot().settings
	settings.reduced_motion = false
	game.change_settings(settings)
	game.dispatch("kitchen_join", "sit")
	await process_frame
	check(game.kitchen_animating and game.model.snapshot().kitchen_checkpoint == "supper", "gesture checkpoint saved before animation")
	game.show_pause()
	var kitchen = game.world_container.get_child(0)
	var elapsed = kitchen.get("gesture_elapsed")
	for _i in range(5): await process_frame
	if elapsed != null: check(kitchen.get("gesture_elapsed") == elapsed, "pause freezes dinner gesture time")
	game.hud.resume_pause()
	var leave_gesture = InputEventAction.new()
	leave_gesture.action = "ui_cancel"
	leave_gesture.pressed = true
	game._unhandled_input(leave_gesture)
	check(not game.kitchen_animating and not game.kitchen_viewing and game.player.enabled and not game.hud.modal_visible(), "Back instantly settles dinner presentation into exploration")
	game.hud.close_all()
	game.route()
	await process_frame
	check(not game.kitchen_animating and game.model.snapshot().kitchen_checkpoint == "supper", "route interruption rebuilds served dinner")
	await step(game,"kitchen_table")
	check(game.hud.content.get_child(0).text == "At the table", "interruption continues directly from dinner")
	settings = game.model.snapshot().settings
	settings.reduced_motion = true
	game.change_settings(settings)
	await step(game,"kitchen_share","bread")
	check(game.model.snapshot().kitchen_checkpoint == "conversation", "interrupted route completes physical exchange")
	await step(game,"kitchen_departure","ask")
	await step(game,"reset")
	check(game.model.snapshot().kitchen_checkpoint == "locked" and not game.kitchen_viewing and not game.kitchen_animating, "new journey clears kitchen and presentation")
