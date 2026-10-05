extends SceneTree
var failures := 0
var checks := 0
func check(ok: bool, label: String):
	checks += 1
	print("PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func _initialize(): call_deferred("run")
func step(game, action: String, value: Variant = null):
	game.dispatch(action, value)
	while game.racing: await process_frame
	await process_frame
func run():
	var game = load("res://main.tscn").instantiate()
	game.save_path = "user://paper_runtime_" + str(Time.get_ticks_usec()) + ".json"
	root.add_child(game)
	await process_frame
	check(game.has_method("dispatch_paper"),"runtime routes sign actions")
	check(game.hud.has_method("show_paper_config"),"accessible sign controls available")
	check(game.hud.has_method("show_paper_dialogue"),"authored conservatory dialogue available")
	var settings = game.model.snapshot().settings
	settings.reduced_motion = true
	settings.text_scale = 2.0
	game.change_settings(settings)
	for action in ["leave_apartment","meet_stranger","read_board","board_train","meet_passenger","arrive_shore","assist"]: await step(game,action)
	await step(game,"choose_camera","unused")
	await step(game,"resolve_action","skipped")
	for action in ["return_train","have_breakfast","finish","begin_fair"]: await step(game,action)
	await step(game,"fair_greeting","watch")
	await step(game,"set_race_mode","watch")
	await step(game,"release_boat")
	await step(game,"inspect_fair","watch")
	await step(game,"level_pond","ada")
	await step(game,"release_boat")
	await step(game,"fair_departure","wait")
	check(game.hud.footer.get_children().any(func(b): return b.text.contains("conservatory")), "fair completion offers explicit chapter adapter")
	await step(game,"begin_paper")
	check(game.model.snapshot().get("paper_checkpoint", "missing") == "arrival", "paper begins only after explicit continue")
	if game.model.snapshot().get("paper_checkpoint", "missing") != "arrival":
		game.queue_free()
		await process_frame
		quit(1)
		return
	check(game.hud.content.get_child(1).text.contains("unopened"), "camera continuity remains explicit")
	await step(game,"paper_greeting","begin")
	check(game.model.snapshot().paper_checkpoint == "workshop", "Noor receives dimensions before assembly")
	await step(game,"paper_config","star")
	check(game.hud.footer.get_child_count() == 4, "three star presets and back control")
	game.show_pause()
	game.hud.resume_pause()
	await process_frame
	check(game.hud.content.get_child(0).text == "The hanging rail", "pause restores assembly focus/body")
	await step(game,"set_paper_star","empty")
	check(not game.hud.modal_visible() and game.player.enabled, "piece choice returns to visible physical preview")
	for pair in [["set_paper_layout","star_leaf_boat"],["set_paper_length","long"],["set_paper_mode","watch"],["set_paper_fold","enough"]]: await step(game,pair[0],pair[1])
	var protected_path = game.save_path + ".future"
	var future = game.model.snapshot()
	future.schema_version = 99
	var fixture = FileAccess.open(protected_path, FileAccess.WRITE)
	fixture.store_string(JSON.stringify(future))
	fixture.close()
	var normal_path = game.save_path
	game.save_path = protected_path
	await step(game, "set_paper_length", "short")
	check(game.hud.notice.text.contains("Unsaved progress"), "failed-save notice survives configuration preview")
	game.save_path = normal_path
	await step(game, "set_paper_length", "long")
	var configured = game.model.snapshot()
	game.hud.close_all()
	game.route()
	check(game.model.snapshot().paper == configured.paper, "interrupted room reload preserves exact arrangement")
	await step(game,"paper_close_view")
	check(not game.player.enabled and game.world_container.get_child(0).get_node_or_null("PaperCloseCamera") != null, "optional stable close view shows physical sign")
	check(not game.world_container.get_child(0).get_node("MiraName").visible, "close view keeps floating actor names off the object")
	game.show_pause()
	var back = InputEventAction.new()
	back.action = "ui_cancel"
	back.pressed = true
	game._unhandled_input(back)
	check(not game.hud.pause_active and game.paper_viewing, "pause back resumes same close view")
	await step(game,"paper_leave_view")
	check(game.player.enabled, "leaving close view restores exploration")
	check(game.world_container.get_child(0).get_node("MiraName").visible, "close view restores actor name labels")
	await step(game,"raise_paper")
	check(game.model.snapshot().paper_checkpoint == "raised", "raise is a durable checkpoint")
	check(game.hud.content.get_child(1).text.contains("clear spot") and game.hud.content.get_child(1).text.contains("shore career"), "spectator and omitted-fold routes have authored outcomes")
	await step(game,"finish_paper")
	check(game.model.snapshot().paper_checkpoint == "complete", "sign finishes on watch route")
	var completed = game.model.snapshot()
	game.hud.close_all()
	game.route()
	await step(game,"paper_courtyard")
	check(game.world_container.get_child(0).get_node_or_null("MountedPaperSign") != null, "completed object mounted in actual fair courtyard")
	check(not game.world_container.get_child(0).get_node("Booth/BoothSign").visible, "finished object replaces provisional booth board")
	await step(game,"paper_inspect")
	check(not game.hud.footer.get_children().any(func(b): return b.text.contains("shadow")), "courtyard only offers available close views")
	check(game.hud.content.get_child(1).text.contains("empty star") and game.hud.content.get_child(1).text.contains("long strings"), "revisit describes exact retained physical configuration")
	check(game.store.load_snapshot(game.save_path).data.paper == completed.paper, "save reload keeps exact completed object")
	check(not game.model.apply("raise_paper"), "repeated raise cannot farm consequence")
	game.paper_courtyard = true
	await step(game, "reset")
	check(not game.paper_courtyard, "new journey clears courtyard presentation route")
	game.queue_free()
	await process_frame
	print("PAPER RUNTIME ",checks," checks ",failures," failures")
	call_deferred("quit", 1 if failures else 0)
